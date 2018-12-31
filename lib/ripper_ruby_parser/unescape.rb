# frozen_string_literal: true

module RipperRubyParser
  # Implements string unescaping
  #
  # @api private
  module Unescape
    ESCAPE_SEQUENCE_REGEXP =
      /\\(
        [0-7]{1,3}        | # octal character
        x[0-9a-fA-F]{1,2} | # hex byte
        u[0-9a-fA-F]+     | # unicode character
        u{[0-9a-fA-F]{4}} | # unicode character
        M-\\C-.           | # meta-ctrl
        C-\\M-.           | # ctrl-meta
        M-\\c.            | # meta-ctrl (shorthand)
        c\\M-.            | # ctrl-meta (shorthand)
        C-.               | # control (regular)
        c.                | # control (shorthand)
        M-.               | # meta
        \n                | # line continuation
        .                   # single-character
      )/x.freeze

    SINGLE_LETTER_ESCAPES = {
      'a' => "\a",
      'b' => "\b",
      'e' => "\e",
      'f' => "\f",
      'n' => "\n",
      'r' => "\r",
      's' => "\s",
      't' => "\t",
      'v' => "\v"
    }.freeze

    SINGLE_LETTER_ESCAPES_REGEXP =
      Regexp.new("^[#{SINGLE_LETTER_ESCAPES.keys.join}]$")

    def simple_unescape(string)
      string.gsub(/\\(
        '   | # single quote
        \\    # backslash
      )/x) do
        Regexp.last_match[1]
      end
    end

    def simple_unescape_wordlist_word(string)
      string.gsub(/\\(
        '   | # single quote
        \\  | # backslash
        [ ] | # space
        \n    # newline
      )/x) do
        Regexp.last_match[1]
      end
    end

    def unescape(string)
      string.gsub(ESCAPE_SEQUENCE_REGEXP) do
        bare = Regexp.last_match[1]
        if bare == "\n"
          ''
        else
          unescaped_value(bare)
        end
      end
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
          ''
        else
          '\\\\'
        end
      end
    end

    private

    def unescaped_value(bare)
      case bare
      when SINGLE_LETTER_ESCAPES_REGEXP
        SINGLE_LETTER_ESCAPES[bare]
      when /^x/
        hex_to_char(bare[1..-1])
      when /^u\{/
        hex_to_unicode_char(bare[2..-2])
      when /^u/
        hex_to_unicode_char(bare[1..4]) +
          (extra_compatible ? '' : bare[5..-1])
      when /^(c|C-).$/
        control(bare[-1].ord).chr
      when /^M-.$/
        meta(bare[-1].ord).chr
      when /^(M-\\C-|C-\\M-|M-\\c|c\\M-).$/
        meta(control(bare[-1].ord)).chr
      when /^[0-7]+/
        bare.to_i(8).chr
      else
        bare
      end
    end

    def hex_to_unicode_char(str)
      str.to_i(16).chr(Encoding::UTF_8)
    end

    def hex_to_char(str)
      str.to_i(16).chr
    end

    def control(val)
      val & 0b1001_1111
    end

    def meta(val)
      val | 0b1000_0000
    end
  end
end
