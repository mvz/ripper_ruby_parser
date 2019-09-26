# frozen_string_literal: true

module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for literals
    module Literals
      def process_string_literal(exp)
        _, content = exp.shift 2
        process(content)
      end

      def process_string_content(exp)
        _, *rest = shift_all exp
        line, string, rest = extract_string_parts(rest)

        if rest.empty?
          with_line_number(line, s(:str, string))
        else
          s(:dstr, string, *rest)
        end
      end

      alias process_word process_string_content

      def process_string_embexpr(exp)
        _, list = exp.shift 2

        val = process(list.sexp_body.first)

        case val.sexp_type
        when :str, :dstr
          val
        when :void_stmt
          s(:dstr, '', s(:evstr))
        else
          s(:dstr, '', s(:evstr, val))
        end
      end

      def process_string_dvar(exp)
        _, list = exp.shift 2
        val = process(list)
        s(:dstr, '', s(:evstr, val))
      end

      def process_string_concat(exp)
        _, left, right = exp.shift 3

        left = process(left)
        right = process(right)

        if left.sexp_type == :str
          merge_left_into_right(left, right)
        else
          merge_right_into_left(left, right)
        end
      end

      def process_xstring_literal(exp)
        _, content = exp.shift 2
        process(content)
      end

      def process_xstring(exp)
        _, *rest = shift_all exp
        line, string, rest = extract_string_parts(rest)
        if rest.empty?
          s(:xstr, string).line(line)
        else
          s(:dxstr, string, *rest)
        end
      end

      def process_regexp_literal(exp)
        _, content, (_, flags,) = exp.shift 3

        content = process(content)
        numflags = character_flags_to_numerical flags

        if content.length == 2
          return with_line_number(content.line, s(:lit, Regexp.new(content.last, numflags)))
        end

        content.sexp_type = :dregx_once if /o/.match?(flags)
        content << numflags unless numflags == 0
        content
      end

      def process_regexp(exp)
        _, *rest = shift_all exp
        line, string, rest = extract_string_parts(rest)
        with_line_number(line, s(:dregx, string, *rest))
      end

      def process_symbol_literal(exp)
        _, symbol = exp.shift 2
        handle_symbol_content(symbol)
      end

      def process_symbol(exp)
        _, node = exp.shift 2
        handle_symbol_content(node)
      end

      def process_dyna_symbol(exp)
        _, node = exp.shift 2
        handle_dyna_symbol_content(node)
      end

      def process_qsymbols(exp)
        _, *items = shift_all(exp)
        items = items.map { |item| handle_symbol_content(item) }
        s(:qsymbols, *items)
      end

      def process_symbols(exp)
        _, *items = shift_all(exp)
        items = items.map { |item| handle_dyna_symbol_content(item) }
        s(:symbols, *items)
      end

      INTERPOLATING_HEREDOC = /^<<[-~]?[^-~']/.freeze
      NON_INTERPOLATING_HEREDOC = /^<<[-~]?'/.freeze
      INTERPOLATING_STRINGS = ['"', '`', ':"', /^%Q.$/, /^%.$/].freeze
      NON_INTERPOLATING_STRINGS = ["'", ":'", /^%q.$/].freeze
      INTERPOLATING_WORD_LIST = /^%[WI].$/.freeze
      NON_INTERPOLATING_WORD_LIST = /^%[wi].$/.freeze
      REGEXP_LITERALS = ['/', /^%r.$/].freeze

      def process_at_tstring_content(exp)
        _, content, pos, delim = exp.shift 4
        string = handle_string_unescaping(content, delim)
        string = handle_string_encoding(string, delim)
        with_position(pos, s(:str, string))
      end

      def process_array(exp)
        _, elems = exp.shift 2
        return s(:array) if elems.nil?

        process(elems).tap { |arr| arr.sexp_type = :array }
      end

      # Handle hash literals sexps. These can be either empty, or contain a
      # nested :assoclist_from_args Sexp.
      #
      # @example Empty hash
      #   s(:hash, nil)
      # @example Hash with contents
      #   s(:hash, s(:assoclist_from_args, ...))
      def process_hash(exp)
        _, body = exp.shift 2
        return s(:hash) unless body

        _, elems = body
        s(:hash, *make_hash_items(elems))
      end

      # @example
      #   s(:assoc_splat, s(:vcall, s(:@ident, "bar")))
      def process_assoc_splat(exp)
        _, param = exp.shift 2
        s(:kwsplat, process(param))
      end

      private

      def extract_string_parts(list)
        return nil, '', [] if list.empty?

        list = merge_raw_string_literals list
        list = map_process_list list

        parts = list.flat_map do |item|
          type, val, *rest = item
          if type == :dstr
            if val.empty?
              rest
            else
              [s(:str, val), *rest]
            end
          else
            [item]
          end
        end

        string = ''
        while parts.first&.sexp_type == :str
          str = parts.shift
          line ||= str.line
          string += str.last
        end

        return line, string, parts
      end

      def merge_raw_string_literals(list)
        chunks = list.chunk { |it| it.sexp_type == :@tstring_content }
        chunks.flat_map do |is_simple, items|
          if is_simple && items.count > 1
            head = items.first
            contents = items.map { |it| it[1] }.join
            [s(:@tstring_content, contents, head[2], head[3])]
          else
            items
          end
        end
      end

      def character_flags_to_numerical(flags)
        numflags = 0

        numflags = Regexp::MULTILINE if /m/.match?(flags)
        numflags |= Regexp::EXTENDED if /x/.match?(flags)
        numflags |= Regexp::IGNORECASE if /i/.match?(flags)

        numflags |= Regexp::NOENCODING if /n/.match?(flags)
        numflags |= Regexp::FIXEDENCODING if /[ues]/.match?(flags)

        numflags
      end

      def handle_dyna_symbol_content(node)
        type, *body = *process(node)
        case type
        when :str, :xstr
          s(:lit, body.first.to_sym)
        when :dstr, :dxstr
          s(:dsym, *body)
        end
      end

      def handle_symbol_content(node)
        if node.sexp_type == :'@kw'
          symbol, position = extract_node_symbol_with_position(node)
          with_position(position, s(:lit, symbol))
        else
          processed = process(node)
          symbol = processed.last.to_sym
          line = processed.line
          with_line_number(line, s(:lit, symbol))
        end
      end

      def merge_left_into_right(left, right)
        right[1] = left.last + right[1]
        right
      end

      def merge_right_into_left(left, right)
        if right.sexp_type == :str
          left.push right
        else
          _, first, *rest = right
          left.push s(:str, first) unless first.empty?
          left.push(*rest)
        end
      end

      def handle_string_unescaping(content, delim)
        case delim
        when INTERPOLATING_HEREDOC
          unescape(content)
        when *INTERPOLATING_STRINGS
          unescape(content)
        when INTERPOLATING_WORD_LIST
          unescape_wordlist_word(content)
        when *NON_INTERPOLATING_STRINGS
          simple_unescape(content)
        when *REGEXP_LITERALS
          unescape_regexp(content)
        when NON_INTERPOLATING_WORD_LIST
          simple_unescape_wordlist_word(content)
        else
          content
        end
      end

      def handle_string_encoding(string, delim)
        case delim
        when INTERPOLATING_HEREDOC, INTERPOLATING_WORD_LIST, *INTERPOLATING_STRINGS
          fix_encoding string
        else
          string
        end
      end

      # Process list of items that can be either :assoc_new or :assoc_splat
      def make_hash_items(elems)
        result = s()
        elems.each do |sub_exp|
          if sub_exp.sexp_type == :assoc_new
            sub_exp.sexp_body.each { |elem| result << process(elem) }
          else # :assoc_splat
            result << process(sub_exp)
          end
        end
        result
      end
    end
  end
end
