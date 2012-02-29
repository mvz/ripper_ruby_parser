require 'sexp_processor'

module RipperRubyParser
  class SexpProcessor < ::SexpProcessor
    def process exp
      unless exp.sexp_type.is_a? Symbol
        exp.unshift :__empty
      end

      super exp
    end

    def process_program exp
      exp.shift
      content = exp.shift
      process(content)
    end

    def process___empty exp
      exp.shift
      content = exp.shift
      content
    end
  end
end
