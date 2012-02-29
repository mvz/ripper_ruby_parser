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

    def process_string_literal exp
      exp.shift
      content = exp.shift
      assert_type content, :string_content
      inner = content[1]
      assert_type inner, :@tstring_content
      string = inner[1]
      s(:str, string)
    end
  end
end
