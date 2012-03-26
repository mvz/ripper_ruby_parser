require 'ripper_ruby_parser/commenting_sexp_builder'
require 'ripper_ruby_parser/sexp_processor'

module RipperRubyParser
  # Main parser class. Brings together Ripper and our
  # RipperRubyParser::SexpProcessor.
  class Parser
    def initialize processor=SexpProcessor.new
      @processor = processor
    end

    def parse source, filename='(string)', lineno=1
      parser = CommentingSexpBuilder.new(source, filename, lineno)
      result = parser.parse
      raise "Ripper parse failed." if result.nil?
      exp = Sexp.from_array(result)
      @processor.filename = filename
      @processor.process exp
    end
  end
end

