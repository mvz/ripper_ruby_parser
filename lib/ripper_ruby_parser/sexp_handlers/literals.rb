module RipperRubyParser
  module SexpHandlers
    module Literals
      def process_string_literal exp
        _, content = exp.shift 2
        process(content)
      end

      def process_string_content exp
        exp.shift

        string, rest = extract_unescaped_string_parts exp

        if rest.empty?
          s(:str, string)
        else
          s(:dstr, string, *rest)
        end
      end

      def process_string_embexpr exp
        _, list = exp.shift 2
        val = process(list.first)
        if val.sexp_type == :str
          val
        else
          s(:evstr, val)
        end
      end

      def process_xstring_literal exp
        _, content = exp.shift 2
        string, rest = extract_unescaped_string_parts content
        if rest.empty?
          s(:xstr, string)
        else
          s(:dxstr, string, *rest)
        end
      end

      def process_regexp_literal exp
        _, content, (_, flags, _) = exp.shift 3

        string, rest = extract_string_parts content

        numflags = 0
        flags =~ /m/ and numflags |= Regexp::MULTILINE
        flags =~ /x/ and numflags |= Regexp::EXTENDED
        flags =~ /i/ and numflags |= Regexp::IGNORECASE

        flags =~ /n/ and numflags |= Regexp::NOENCODING
        flags =~ /[ues]/ and numflags |= Regexp::FIXEDENCODING

        while not(rest.empty?) and rest.first.sexp_type == :str
          str = rest.shift
          string += str[1]
        end

        if rest.empty?
          s(:lit, Regexp.new(string, numflags))
        else
          rest << numflags if numflags > 0
          sexp_type = if flags =~ /o/
                     :dregx_once
                   else
                     :dregx
                   end
          s(sexp_type, string, *rest)
        end
      end

      def process_symbol_literal exp
        _, symbol = exp.shift 2
        process(symbol)
      end

      def process_symbol exp
        _, node = exp.shift 2
        with_position_from_node_symbol(node) {|sym| s(:lit, sym) }
      end

      def process_dyna_symbol exp
        _, list = exp.shift 2

        string, rest = extract_unescaped_string_parts list
        if rest.empty?
          s(:lit, string.to_sym)
        else
          s(:dsym, string, *rest)
        end
      end

      def process_at_tstring_content exp
        _, string, _ = exp.shift 3
        s(:str, string)
      end

      private

      def extract_string_parts exp
        inner = exp.shift

        string = process(inner)
        rest = []

        if string.nil?
          string = ""
        elsif string.sexp_type == :str
          string = string[1]
        else
          rest << string
          string = ""
        end

        until exp.empty? do
          result = process(exp.shift)
          rest << result
        end

        return string, rest
      end

      def extract_unescaped_string_parts exp
        string, rest = extract_string_parts exp

        string = unescape(string)

        rest.each do |sub_exp|
          if sub_exp.sexp_type == :str
            sub_exp[1] = unescape(sub_exp[1])
          end
        end

        return string, rest
      end

      def unescape string
        string.gsub(/(\\[^)])/) do
          eval "\"#{$1}\""
        end
      end
    end
  end
end
