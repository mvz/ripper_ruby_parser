require 'ripper_ruby_parser/sexp_builder'
require 'ripper_ruby_parser/sexp_processor'

module RipperRubyParser
  # Main parser class. Brings together Ripper and our
  # RipperRubyParser::SexpProcessor.
  class Parser
    def initialize processor=SexpProcessor.new
      @processor = processor
    end

    def parse source, filename='-', lineno=1
      parser = SexpBuilder.new(source, filename, lineno)
      exp = Sexp.from_array(parser.parse)
      @processor.process exp
    end
  end
end

