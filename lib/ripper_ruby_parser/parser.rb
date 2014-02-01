require 'ripper_ruby_parser/commenting_ripper_parser'
require 'ripper_ruby_parser/sexp_processor'

module RipperRubyParser
  # Main parser class. Brings together Ripper and our
  # RipperRubyParser::SexpProcessor.
  class Parser
    attr_accessor :extra_compatible

    def initialize processor=SexpProcessor.new
      @processor = processor
      @extra_compatible = false
    end

    def parse source, filename='(string)', lineno=1
      parser = CommentingRipperParser.new(source, filename, lineno)
      exp = parser.parse

      @processor.filename = filename
      @processor.extra_compatible = extra_compatible
      result = @processor.process exp

      if result == s(:void_stmt)
        nil
      else
        result
      end
    end
  end
end

