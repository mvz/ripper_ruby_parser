require 'sexp_processor'
require 'ripper_ruby_parser/sexp_handlers'
require 'ripper_ruby_parser/sexp_ext'

module RipperRubyParser
  # Processes the sexp created by Ripper to what RubyParser would produce.
  class SexpProcessor < ::SexpProcessor
    def initialize
      super

      # TODO: Find these automatically

      @processors[:@int] = :process_at_int
      @processors[:@float] = :process_at_float

      @processors[:@const] = :process_at_const
      @processors[:@ident] = :process_at_ident
      @processors[:@cvar] = :process_at_cvar
      @processors[:@gvar] = :process_at_gvar
      @processors[:@ivar] = :process_at_ivar
      @processors[:@kw] = :process_at_kw
      @processors[:@backref] = :process_at_backref

      @processors[:@tstring_content] = :process_at_tstring_content
    end

    def process exp
      return nil if exp.nil?
      exp.fix_empty_type

      result = super
      trickle_up_line_numbers result
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

    def process_module exp
      _, const_ref, body = exp.shift 3
      const = const_ref_to_const const_ref
      s(:module, const, class_or_module_body(body))
    end

    def process_class exp
      _, const_ref, parent, body = exp.shift 4
      const = const_ref_to_const const_ref
      parent = process(parent)
      s(:class, const, parent, class_or_module_body(body))
    end

    def process_bodystmt exp
      _, body, rescue_block, _, ensure_block = exp.shift 5

      body = map_body body

      unless rescue_block or ensure_block
        return s(:scope, s(:block, *body))
      end

      body = wrap_in_block(body)

      if rescue_block
        body = s(:rescue, body, process(rescue_block))
      end

      if ensure_block
        body = s(:ensure, body, process(ensure_block))
      end

      s(:scope, body)
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
      s(:colon2, process(left), extract_node_symbol(right))
    end

    def process_const_ref exp
      _, ref = exp.shift 3
      process(ref)
    end

    def process_top_const_ref exp
      _, ref = exp.shift 2
      s(:colon3, extract_node_symbol(ref))
    end

    def process_paren exp
      _, body = exp.shift 2
      if body.size == 0
        s()
      elsif body.first.is_a? Symbol
        process body
      else
        process body[0]
      end
    end

    def process_comment exp
      _, comment, inner = exp.shift 3
      sexp = process(inner)
      sexp.comments = comment
      sexp
    end

    # number literals
    def process_at_int exp
      _, val, pos = exp.shift 3
      with_position(pos, s(:lit, val.to_i))
    end

    def process_at_float exp
      _, val, pos = exp.shift 3
      with_position(pos, s(:lit, val.to_f))
    end

    # symbol-like sexps
    def process_at_const exp
      make_identifier(:const, exp)
    end

    def process_at_cvar exp
      make_identifier(:cvar, exp)
    end

    def process_at_gvar exp
      make_identifier(:gvar, exp)
    end

    def process_at_ivar exp
      make_identifier(:ivar, exp)
    end

    def process_at_ident exp
      make_identifier(:lvar, exp)
    end

    def process_at_kw exp
      sym = extract_node_symbol(exp)
      if sym == :__FILE__
        s(:str, "(string)")
      else
        s(sym)
      end
    end

    def process_at_backref exp
      _, str, _ = exp.shift 3
      s(:nth_ref, str[1..-1].to_i)
    end

    private

    def const_ref_to_const const_ref
      const = process(const_ref)
      if const.sexp_type == :const
        const = const[1]
      end
      return const
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

    def make_identifier(type, exp)
      with_position_from_node_symbol(exp) {|ident|
        s(type, ident) }
    end

    def trickle_up_line_numbers exp
      exp.map! do |sub_exp|
        if sub_exp.is_a? Sexp
          exp.line ||= sub_exp.line
          trickle_up_line_numbers sub_exp
        else
          sub_exp
        end
      end
    end
  end
end
