require 'ripper_ruby_parser/sexp_ext'
require 'sexp_processor'

module RipperRubyParser
  # Processes the sexp created by Ripper to what RubyParser would produce.
  class SexpProcessor < ::SexpProcessor
    def process exp
      return nil if exp.nil?
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

    def process_module exp
      _, const_ref, body = exp.shift 3
      const = const_node_to_symbol const_ref[1]
      s(:module, const, class_body(body))
    end

    def process_class exp
      _, const_ref, parent, body = exp.shift 4
      const = const_node_to_symbol const_ref[1]
      parent = process(parent)
      s(:class, const, parent, class_body(body))
    end

    def process_def exp
      _, ident, params, body = exp.shift 4
      ident = identifier_node_to_symbol ident
      s(:defn, ident, process(params), definition_body(body))
    end

    def process_params exp
      exp.shift 6
      s(:args)
    end

    def process_bodystmt exp
      _, body, _, _, _ = exp.shift 5
      body = body.
        map { |sub_exp| process(sub_exp) }.
        reject { |sub_exp| sub_exp.sexp_type == :void_stmt }
      s(:scope, s(:block, *body))
    end

    def process_var_ref exp
      _, contents = exp.shift 2
      if contents.sexp_type == :@const
        s(:const, const_node_to_symbol(contents))
      else
        s(:var_ref, contents)
      end
    end

    def identifier_node_to_symbol exp
      assert_type exp, :@ident
      _, ident, _ = exp.shift 3

      ident.to_sym
    end

    def const_node_to_symbol exp
      assert_type exp, :@const
      _, ident, _ = exp.shift 3

      ident.to_sym
    end

    def definition_body exp
      scope = process exp
      block = scope[1]
      if block.length == 1
        block.push s(:nil)
      end
      scope
    end

    def class_body exp
      scope = process exp
      block = scope[1]
      block.shift
      if block.length <= 1
        s(:scope, *block)
      else
        s(:scope, s(:block, *block))
      end
    end
  end
end
