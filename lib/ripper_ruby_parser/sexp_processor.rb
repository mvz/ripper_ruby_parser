require 'ripper_ruby_parser/sexp_ext'
require 'sexp_processor'

module RipperRubyParser
  # Processes the sexp created by Ripper to what RubyParser would produce.
  class SexpProcessor < ::SexpProcessor
    def process exp
      exp.fix_empty_type

      super
    end

    def process_program exp
      _, content = exp.shift 2

      if content.length == 1
        process(content.first)
      else
        statements = content.map { |sub_exp| process(sub_exp) }
        s(:block, *statements)
      end
    end

    def process_string_literal exp
      _, content = exp.shift 2

      assert_type content, :string_content
      inner = content[1]

      assert_type inner, :@tstring_content
      string = inner[1]

      s(:str, string)
    end

    def process_args_add_block exp
      _, content, _ = exp.shift 3

      args = content.map { |sub_exp| process(sub_exp) }

      s(:arglist, *args)
    end

    def process_command exp
      _, ident, arglist = exp.shift 3

      ident = identifier_node_to_symbol ident
      arglist = process arglist

      s(:call, nil, ident, arglist)
    end

    def identifier_node_to_symbol exp
      assert_type exp, :@ident
      _, ident, _ = exp.shift 3

      ident.to_sym
    end
  end
end
