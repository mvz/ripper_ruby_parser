# coding: utf-8
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
        case val.sexp_type
        when :str
          val
        when :void_stmt
          s(:dstr, "", s(:evstr))
        else
          s(:dstr, "", s(:evstr, val))
        end
      end

      def process_string_dvar exp
        _, list = exp.shift 2
        val = process(list)
        s(:dstr, "", s(:evstr, val))
      end

      def process_string_concat exp
        _, left, right = exp.shift 3

        left = process(left)
        right = process(right)

        if left.sexp_type == :str
          right[1] = left[1] + right[1]
          right
        else # Expecting left.sexp_type == :dstr
          _, first, *rest = right
          left.push s(:str, first) unless first.empty?
          left.push(*rest)
          left
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
        numflags = character_flags_to_numerical flags

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
        string = ""
        rest = []

        until exp.empty? do
          result = process(exp.shift)
          rest << result
        end

        while not(rest.empty?) and rest.first.sexp_type == :str
          str = rest.shift
          string += str[1]
        end

        rest = rest.map { |se| se.sexp_type == :dstr ? se.last : se }

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

      SINGLE_LETTER_ESCAPES = {
        "a" => "\a",
        "b" => "\b",
        "e" => "\e",
        "f" => "\f",
        "n" => "\n",
        "r" => "\r",
        "s" => "\s",
        "t" => "\t",
        "v" => "\v",
      }

      SINGLE_LETTER_ESCAPES_REGEXP =
        Regexp.new("^[#{SINGLE_LETTER_ESCAPES.keys.join}]$")

      def unescape string
        string.gsub(/\\(
          [0-7]{1,3}        | # octal character
          x[0-9a-fA-F]{1,2} | # hex byte
          u[0-9a-fA-F]{4}   | # unicode character
          M-\\C-.           | # meta-ctrl
          C-\\M-.           | # ctrl-meta
          M-\\c.            | # meta-ctrl (shorthand)
          c\\M-.            | # ctrl-meta (shorthand)
          C-.               | # control (regular)
          c.                | # control (shorthand)
          M-.               | # meta
          .                   # single-character
        )/x) do
          bare = $1
          case bare
          when SINGLE_LETTER_ESCAPES_REGEXP
            SINGLE_LETTER_ESCAPES[bare]
          when /^x/
            bare[1..-1].to_i(16).chr
          when /^u/
            bare[1..-1].to_i(16).chr(Encoding::UTF_8)
          when /^(?:c|C-)(.)$/
            ($1.ord & 0b1001_1111).chr
          when /^M-(.)$/
            ($1.ord | 0b1000_0000).chr
          when /^(?:M-\\C-|C-\\M-|M-\\c|c\\M-)(.)$/
            ($1.ord & 0b1001_1111 | 0b1000_0000).chr
          when /^[0-7]+/
            bare.to_i(8).chr
          else
            bare
          end
        end
      end

      def character_flags_to_numerical flags
        numflags = 0

        flags =~ /m/ and numflags |= Regexp::MULTILINE
        flags =~ /x/ and numflags |= Regexp::EXTENDED
        flags =~ /i/ and numflags |= Regexp::IGNORECASE

        flags =~ /n/ and numflags |= Regexp::NOENCODING
        flags =~ /[ues]/ and numflags |= Regexp::FIXEDENCODING

        numflags
      end

    end
  end
end
