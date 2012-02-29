require 'sexp_processor'

module RipperRubyParser
  class SexpProcessor < ::SexpProcessor
    def process exp
      fix_empty_type exp

      super exp
    end

    def process_program exp
      exp.shift
      content = exp.shift
      fix_empty_type content
      assert_type content, :__empty
      process(content[1])
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

    def process_args_add_block exp
      exp.shift
      content = exp.shift
      exp.shift

      fix_empty_type content
      assert_type content, :__empty

      s(:arglist, content[1])
    end

    private

    def fix_empty_type exp
      unless exp.sexp_type.is_a? Symbol
        exp.unshift :__empty
      end
    end
  end
end
