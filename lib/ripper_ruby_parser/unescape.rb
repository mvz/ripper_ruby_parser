# frozen_string_literal: true

module RipperRubyParser
  # Implements string unescaping
  #
  # @api private
  module Unescape
    ESCAPE_SEQUENCE_REGEXP =
      /\\(
        [0-7]{1,3}          | # octal character
        x[0-9a-fA-F]{1,2}   | # hex byte
        u[0-9a-fA-F]{4}     | # unicode character
        u{[0-9a-fA-F]{4,6}} | # unicode character
        M-\\C-.             | # meta-ctrl
        C-\\M-.             | # ctrl-meta
        M-\\c.              | # meta-ctrl (shorthand)
        c\\M-.              | # ctrl-meta (shorthand)
        C-.                 | # control (regular)
        c.                  | # control (shorthand)
        M-.                 | # meta
        \n                  | # line break
        .                     # other single character
      )/x

    SINGLE_LETTER_ESCAPES = {
      "a" => "\a",
      "b" => "\b",
      "e" => "\e",
      "f" => "\f",
      "n" => "\n",
      "r" => "\r",
      "s" => "\s",
      "t" => "\t",
      "v" => "\v"
    }.freeze

    SINGLE_LETTER_ESCAPES_REGEXP =
      Regexp.new("^[#{SINGLE_LETTER_ESCAPES.keys.join}]$")

    DELIMITER_PAIRS = {
      "(" => "()",
      "<" => "<>",
      "[" => "[]",
      "{" => "{}"
    }.freeze

    def simple_unescape(string, delimiter)
      delimiters = delimiter_regexp_pattern(delimiter)
      string.gsub(/
                  \\ # a backslash
                  (  # followed by a
                    #{delimiters} | # delimiter or
                    \\              # backslash
                  )/x) do
                    Regexp.last_match[1]
                  end
    end

    def simple_unescape_wordlist_word(string, delimiter)
      delimiters = delimiter_regexp_pattern(delimiter)
      string.gsub(/
                  \\ # a backslash
                  (  # followed by a
                    #{delimiters} | # delimiter or
                    \\            | # backslash or
                    [ ]           | # space or
                    \n              # newline
                  )
                  /x) do
                    Regexp.last_match[1]
                  end
    end

    def unescape(string)
      string = string.dup if string.frozen?
      string.force_encoding("ASCII-8BIT")
      result = string.gsub(ESCAPE_SEQUENCE_REGEXP) do
        bare = Regexp.last_match[1]
        if bare == "\n"
          ""
        else
          unescaped_value(bare).force_encoding("ASCII-8BIT")
        end
      end
      fix_encoding result
    end

    def unescape_wordlist_word(string)
      string.gsub(ESCAPE_SEQUENCE_REGEXP) do
        bare = Regexp.last_match[1]
        unescaped_value(bare)
      end
    end

    def fix_encoding(string)
      unless string.encoding == Encoding::UTF_8
        dup = string.dup.force_encoding Encoding::UTF_8
        return dup if dup.valid_encoding?
      end
      string
    end

    def unescape_regexp(string)
      string.gsub(/\\(\n|\\)/) do
        bare = Regexp.last_match[1]
        case bare
        when "\n"
          ""
        else
          "\\\\"
        end
      end
    end

    private

    def unescaped_value(bare)
      case bare
      when SINGLE_LETTER_ESCAPES_REGEXP
        SINGLE_LETTER_ESCAPES[bare].dup
      when /^x/
        unescape_hex_char bare
      when /^u/
        unescape_unicode_char bare
      when /^(c|C-|M-|M-\\C-|C-\\M-|M-\\c|c\\M-).$/
        unescape_meta_control bare
      when /^[0-7]+/
        unescape_octal bare
      else
        bare
      end
    end

    def unescape_hex_char(bare)
      hex_to_char(bare[1..])
    end

    def unescape_unicode_char(bare)
      hex_chars = if bare.start_with? "u{"
                    bare[2..-2]
                  else
                    bare[1..4]
                  end
      hex_to_unicode_char(hex_chars)
    end

    def unescape_meta_control(bare)
      base_value = bare[-1].ord
      value = case bare
              when /^(c|C-).$/
                control(base_value)
              when /^M-.$/
                meta(base_value)
              when /^(M-\\C-|C-\\M-|M-\\c|c\\M-).$/
                meta(control(base_value))
              end
      value.chr
    end

    def unescape_octal(bare)
      bare.to_i(8).chr
    end

    def hex_to_unicode_char(str)
      str.to_i(16).chr(Encoding::UTF_8)
    end

    def hex_to_char(str)
      str.to_i(16).chr
    end

    def control(val)
      # Special case the \C-? or DEL sequence
      return 127 if val == 63

      val & 0b1001_1111
    end

    def meta(val)
      val | 0b1000_0000
    end

    def delimiter_regexp_pattern(delimiter)
      delimiter = delimiter[-1]
      delimiters = DELIMITER_PAIRS.fetch(delimiter, delimiter)
      delimiters.each_char.map { |it| Regexp.escape it }.join(" | ")
    end
  end
end
