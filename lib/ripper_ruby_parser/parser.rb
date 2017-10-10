require 'ripper_ruby_parser/commenting_ripper_parser'
require 'ripper_ruby_parser/sexp_processor'

module RipperRubyParser
  # Main parser class. Brings together Ripper and our
  # RipperRubyParser::SexpProcessor.
  class Parser
    def parse(source, filename = '(string)', lineno = 1)
      parser = CommentingRipperParser.new(source, filename, lineno)
      exp = parser.parse

      processor = SexpProcessor.new(filename: filename)
      result = processor.process exp

      if result.sexp_type == :void_stmt
        nil
      else
        trickle_up_line_numbers result
        trickle_down_line_numbers result
        result
      end
    end

    private

    def trickle_up_line_numbers(exp)
      exp.each do |sub_exp|
        if sub_exp.is_a? Sexp
          trickle_up_line_numbers sub_exp
          exp.line ||= sub_exp.line
        end
      end
    end

    def trickle_down_line_numbers(exp)
      exp.each do |sub_exp|
        if sub_exp.is_a? Sexp
          sub_exp.line ||= exp.line
          trickle_down_line_numbers sub_exp
        end
      end
    end
  end
end
