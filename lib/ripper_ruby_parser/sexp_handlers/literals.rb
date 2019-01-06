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
        string, rest = extract_string_parts(rest)

        if rest.empty?
          s(:str, string)
        else
          s(:dstr, string, *rest)
        end
      end

      alias process_word process_string_content

      def process_string_embexpr(exp)
        _, list = exp.shift 2

        val = process(list.sexp_body.first)

        case val.sexp_type
        when :str
          val
        when :void_stmt
          s(:dstr, s(:evstr))
        else
          s(:dstr, s(:evstr, val))
        end
      end

      def process_string_dvar(exp)
        _, list = exp.shift 2
        val = process(list)
        s(:dstr, s(:evstr, val))
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
        string, rest = extract_string_parts(rest)
        if rest.empty?
          s(:xstr, string)
        else
          s(:dxstr, string, *rest)
        end
      end

      def process_regexp_literal(exp)
        _, content, (_, flags,) = exp.shift 3

        content = process(content)
        numflags = character_flags_to_numerical flags

        return s(:lit, Regexp.new(content.last, numflags)) if content.length == 2

        content.sexp_type = :dregx_once if flags =~ /o/
        content << numflags unless numflags == 0
        content
      end

      def process_regexp(exp)
        _, *rest = shift_all exp
        string, rest = extract_string_parts(rest)
        s(:dregx, string, *rest)
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
        _, content, _, delim = exp.shift 4
        string = handle_string_unescaping(content, delim)
        string = handle_string_encoding(string, delim)
        s(:str, string)
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
        parts = []

        unless list.empty?
          parts << process(list.shift)
          list.each do |item|
            parts << if extra_compatible && item.sexp_type == :@tstring_content
                       alternative_process_at_tstring_content(item)
                     else
                       process(item)
                     end
          end
        end

        string = ''
        while !parts.empty? && parts.first.sexp_type == :str
          str = parts.shift
          string += str.last
        end

        rest = parts.map { |se| se.sexp_type == :dstr ? se.last : se }

        return string, rest
      end

      def alternative_process_at_tstring_content(exp)
        _, content, _, delim = exp.shift 4
        string = case delim
                 when *INTERPOLATING_STRINGS
                   unescape(content)
                 else
                   content
                 end
        string.force_encoding('ascii-8bit') if string == "\0"
        s(:str, string)
      end

      def character_flags_to_numerical(flags)
        numflags = 0

        numflags = Regexp::MULTILINE if flags =~ /m/
        numflags |= Regexp::EXTENDED if flags =~ /x/
        numflags |= Regexp::IGNORECASE if flags =~ /i/

        numflags |= Regexp::NOENCODING if flags =~ /n/
        numflags |= Regexp::FIXEDENCODING if flags =~ /[ues]/

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
        else
          processed = process(node)
          symbol = processed.last.to_sym
          position = processed.line
        end
        with_line_number(position, s(:lit, symbol))
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
        when INTERPOLATING_HEREDOC, *INTERPOLATING_STRINGS
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
        when INTERPOLATING_HEREDOC, INTERPOLATING_WORD_LIST
          if extra_compatible
            string
          else
            fix_encoding string
          end
        when *INTERPOLATING_STRINGS
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
