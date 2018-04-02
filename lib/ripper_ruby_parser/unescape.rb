module RipperRubyParser
  # Implements string unescaping
  #
  # @api private
  module Unescape
    module_function

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

    def unescape(string)
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
        \n                | # line continuation
        .                   # single-character
      )/x) do
        bare = Regexp.last_match[1]
        case bare
        when SINGLE_LETTER_ESCAPES_REGEXP
          SINGLE_LETTER_ESCAPES[bare]
        when /^x/
          bare[1..-1].to_i(16).chr
        when /^u/
          bare[1..-1].to_i(16).chr(Encoding::UTF_8)
        when /^(c|C-).$/
          (bare[-1].ord & 0b1001_1111).chr
        when /^M-.$/
          (bare[-1].ord | 0b1000_0000).chr
        when /^(M-\\C-|C-\\M-|M-\\c|c\\M-).$/
          (bare[-1].ord & 0b1001_1111 | 0b1000_0000).chr
        when /^[0-7]+/
          bare.to_i(8).chr
        when "\n"
          ''
        else
          bare
        end
      end
    end

    def fix_encoding(string)
      unless string.encoding == Encoding::UTF_8
        dup = string.dup.force_encoding Encoding::UTF_8
        return dup if dup.valid_encoding?
      end
      string
    end

    def process_line_continuations(string)
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
  end
end
