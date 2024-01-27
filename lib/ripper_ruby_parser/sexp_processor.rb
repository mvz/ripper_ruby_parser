# frozen_string_literal: true

require "sexp_processor"
require "ripper_ruby_parser/sexp_handlers"
require "ripper_ruby_parser/unescape"

module RipperRubyParser
  # Processes the sexp created by Ripper to what RubyParser would produce.
  #
  # @api private
  class SexpProcessor < ::SexpProcessor
    include Unescape

    attr_reader :filename, :extra_compatible

    def initialize(filename: nil, extra_compatible: nil)
      super()

      public_methods.each do |name|
        @processors[:"@#{Regexp.last_match(1)}"] = name.to_sym if name =~ /^process_at_(.*)/
      end

      @filename = filename
      @extra_compatible = extra_compatible

      @errors = []

      @in_method_body = false
      @local_variables = []

      @kept_comment = nil
    end

    include SexpHandlers

    def process_program(exp)
      _, content = exp.shift 2

      process content
    end

    def process_module(exp)
      _, const_ref, body, pos = exp.shift 4
      const = const_ref_to_const const_ref
      with_position(pos,
                    s(:module, const, *class_or_module_body(body)))
    end

    def process_class(exp)
      _, const_ref, parent, body, pos = exp.shift 5
      const = const_ref_to_const const_ref
      parent = process(parent)
      with_position(pos,
                    s(:class, const, parent, *class_or_module_body(body)))
    end

    def process_sclass(exp)
      _, klass, block, pos = exp.shift 4
      with_position pos, s(:sclass, process(klass), *class_or_module_body(block))
    end

    def process_stmts(exp)
      _, *statements = shift_all(exp)
      statements = map_unwrap_begin_list map_process_list statements
      line = statements.first.line
      statements = reject_void_stmt statements
      wrap_in_block(statements, line)
    end

    def process_var_ref(exp)
      _, contents = exp.shift 2
      process(contents)
    end

    def process_var_field(exp)
      _, contents = exp.shift 2
      process(contents) || s(:lvar, nil)
    end

    def process_var_alias(exp)
      _, left, right = exp.shift 3
      s(:valias, left[1].to_sym, right[1].to_sym)
    end

    def process_void_stmt(exp)
      _, pos = exp.shift 2
      with_position pos, s(:void_stmt)
    end

    def process_const_path_ref(exp)
      _, left, right = exp.shift 3
      s(:colon2, process(left), make_symbol(process(right)))
    end

    def process_const_path_field(exp)
      s(:const, process_const_path_ref(exp))
    end

    def process_const_ref(exp)
      _, ref = exp.shift 3
      process(ref)
    end

    def process_top_const_ref(exp)
      _, ref = exp.shift 2
      s(:colon3, make_symbol(process(ref)))
    end

    def process_top_const_field(exp)
      s(:const, process_top_const_ref(exp))
    end

    def process_paren(exp)
      _, body = exp.shift 2
      result = process body
      convert_void_stmt_to_nil_symbol result
    end

    def process_comment(exp)
      _, comment, inner = exp.shift 3
      comment = @kept_comment + comment if @kept_comment
      @kept_comment = nil
      sexp = process(inner)
      case sexp.sexp_type
      when :defs, :defn, :module, :class, :sclass
        sexp.comments = comment
      when :iter
        # Drop comment
      else
        @kept_comment = comment
      end
      sexp
    end

    def process_BEGIN(exp)
      _, body, pos = exp.shift 3
      body = reject_void_stmt map_process_list body.sexp_body
      with_position pos, s(:iter, s(:preexe), 0, *body)
    end

    def process_END(exp)
      _, body, pos = exp.shift 3
      body = map_process_list_compact body.sexp_body
      with_position pos, s(:iter, s(:postexe), 0, *body)
    end

    def process_at_label(exp)
      make_literal(exp) { |val| val.chop.to_sym }
    end

    # symbol-like sexps
    def process_at_const(exp)
      make_identifier(:const, exp)
    end

    def process_at_cvar(exp)
      make_identifier(:cvar, exp)
    end

    def process_at_gvar(exp)
      make_identifier(:gvar, exp)
    end

    def process_at_ivar(exp)
      make_identifier(:ivar, exp)
    end

    def process_at_ident(exp)
      make_identifier(:lvar, exp)
    end

    def process_at_op(exp)
      make_identifier(:op, exp)
    end

    def process_at_backtick(exp)
      make_identifier(:backtick, exp)
    end

    def process_at_kw(exp)
      sym, pos = extract_node_symbol_with_position(exp)
      result = case sym
               when :__ENCODING__
                 s(:colon2, s(:const, :Encoding), :UTF_8)
               when :__FILE__
                 s(:str, @filename)
               when :__LINE__
                 s(:lit, pos[0])
               else
                 s(sym)
               end
      with_position(pos, result)
    end

    def process_at_backref(exp)
      _, str, pos = exp.shift 3
      name = str[1..]
      with_position pos do
        if /[0-9]/.match?(name)
          s(:nth_ref, name.to_i)
        else
          s(:back_ref, name.to_sym)
        end
      end
    end

    def process_at_period(exp)
      _, period, = exp.shift 3
      s(:period, period)
    end

    private

    def const_ref_to_const(const_ref)
      const = process(const_ref)
      const = const[1] if const.sexp_type == :const
      const
    end

    def class_or_module_body(exp)
      body = process(exp)

      return [] if body.sexp_type == :void_stmt

      unwrap_block body
    end

    def make_identifier(type, exp)
      with_position_from_node_symbol(exp) do |ident|
        s(type, ident)
      end
    end

    def make_literal(exp)
      _, val, pos = exp.shift 3
      with_position(pos, s(:lit, yield(val)))
    end
  end
end
