require 'sexp_processor'
require 'ripper_ruby_parser/sexp_handlers'
require 'ripper_ruby_parser/sexp_ext'

module RipperRubyParser
  # Processes the sexp created by Ripper to what RubyParser would produce.
  class SexpProcessor < ::SexpProcessor
    def initialize
      super
      @processors[:@int] = :process_at_int
      @processors[:@const] = :process_at_const
      @processors[:@ident] = :process_at_ident
      @processors[:@ivar] = :process_at_ivar
      @processors[:@kw] = :process_at_kv
    end

    def process exp
      return nil if exp.nil?
      exp.fix_empty_type

      super
    end

    include SexpHandlers

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

    def process_symbol_literal exp
      _, symbol = exp.shift 2
      sym = symbol[1]
      s(:lit, extract_node_symbol(sym))
    end

    def process_module exp
      _, const_ref, body = exp.shift 3
      const = const_node_to_symbol const_ref[1]
      s(:module, const, class_or_module_body(body))
    end

    def process_class exp
      _, const_ref, parent, body = exp.shift 4
      const = const_node_to_symbol const_ref[1]
      parent = process(parent)
      s(:class, const, parent, class_or_module_body(body))
    end

    def process_assign exp
      _, lvalue, value = exp.shift 3

      lvalue = process(lvalue)

      if lvalue.sexp_type == :ivar
        sexp_type = :iasgn
      else
        sexp_type = :lasgn
      end

      s(sexp_type, lvalue[1], process(value))
    end

    def process_params exp
      _, normal, defaults, *_ = exp.shift 6

      args = [*normal].map do |id|
        identifier_node_to_symbol id
      end

      assigns = [*defaults].map do |pair|
        sym = identifier_node_to_symbol pair[0]
        val = process pair[1]
        s(:lasgn, sym, val)
      end

      if assigns.length > 0
        args += assigns.map {|lasgn| lasgn[1]}
        args << s(:block, *assigns)
      end

      s(:args, *args)
    end

    def process_array exp
      _, elems = exp.shift 2
      s(:array, *handle_list_with_optional_splat(elems))
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
      process(contents)
    end

    def process_var_field exp
      _, contents = exp.shift 2
      process(contents)
    end

    def process_const_path_ref exp
      _, left, right = exp.shift 3
      s(:colon2, process(left), const_node_to_symbol(right))
    end

    def process_binary exp
      _, left, op, right = exp.shift 4
      s(:call, process(left), op, s(:arglist, process(right)))
    end

    def process_at_int exp
      _, val, _ = exp.shift 3
      s(:lit, val.to_i)
    end

    # symbol-like sexps
    def process_at_const exp
      s(:const, extract_node_symbol(exp))
    end

    def process_at_ivar exp
      s(:ivar, extract_node_symbol(exp))
    end

    def process_at_ident exp
      s(:lvar, extract_node_symbol(exp))
    end

    def process_at_kv exp
      s(extract_node_symbol(exp))
    end

    private

    def const_node_to_symbol exp
      assert_type exp, :@const
      _, ident, _ = exp.shift 3

      ident.to_sym
    end

    def ivar_node_to_symbol exp
      assert_type exp, :@ivar
      extract_node_symbol exp
    end

    def extract_node_symbol exp
      _, ident, _ = exp.shift 3

      ident.to_sym
    end

    def method_body exp
      scope = process exp
      block = scope[1]
      if block.length == 1
        block.push s(:nil)
      end
      scope
    end

    def class_or_module_body exp
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
