require 'ripper_ruby_parser/commenting_ripper_parser'
require 'ripper_ruby_parser/sexp_processor'

module RipperRubyParser
  # Main parser class. Brings together Ripper and our
  # RipperRubyParser::SexpProcessor.
  class Parser

    # @api private
    attr_accessor :extra_compatible

    def initialize
      @extra_compatible = false
    end

    def parse(source, filename = '(string)', lineno = 1)
      parser = CommentingRipperParser.new(source, filename, lineno)
      exp = parser.parse

      processor = SexpProcessor.new(filename: filename, extra_compatible: extra_compatible)
      result = processor.process exp

      if result == s(:void_stmt)
        nil
      else
        result
      end
    end
  end
end
