require 'ripper'
require 'ripper_ruby_parser/sexp_processor'

module RipperRubyParser
  # Main parser class. Brings together Ripper and our
  # RipperRubyParser::SexpProcessor.
  class Parser
    def initialize processor=SexpProcessor.new
      @processor = processor
    end

    def parse source
      exp = Sexp.from_array(Ripper.sexp source)
      @processor.process exp
    end
  end
end

