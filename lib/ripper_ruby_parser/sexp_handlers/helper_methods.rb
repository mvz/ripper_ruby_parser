module RipperRubyParser
  module SexpHandlers
    module HelperMethods
      def handle_potentially_typeless_sexp exp
        if exp.nil?
          s()
        elsif exp.first.is_a? Symbol
          process(exp)
        else
          exp.map! { |sub_exp| handle_potentially_typeless_sexp(sub_exp) }
        end
      end

      def handle_potentially_typeless_sexp_with_fallback_type type, exp
        if exp.nil?
          s(type)
        elsif exp.first.is_a? Symbol
          process(exp)
        else
          exp.map! { |sub_exp| process(sub_exp) }
          exp.unshift type
          exp
        end
      end

      def extract_node_symbol_with_position exp
        return nil if exp.nil?
        return exp if exp.is_a? Symbol
        
        _, ident, pos = exp.shift 3
        return ident.to_sym, pos
      end

      def extract_node_symbol exp
        return nil if exp.nil?
        _, ident, _ = exp.shift 3
        ident.to_sym
      end

      def with_position pos, exp=nil
        (line, _) = pos
        exp = yield if exp.nil?
        with_line_number line, exp
      end

      def with_line_number line, exp
        exp.line = line
        exp
      end

      def with_position_from_node_symbol exp
        sym, pos = extract_node_symbol_with_position exp
        with_position(pos, yield(sym))
      end

      def generic_add_star exp
        _, args, splatarg = exp.shift 3
        items = handle_potentially_typeless_sexp args
        items << s(:splat, process(splatarg))
        until exp.empty?
          items << process(exp.shift)
        end
        items
      end

      def is_literal? exp
        exp.sexp_type == :lit
      end

      def map_body body
        body.
          map { |sub_exp| process(sub_exp) }.
          reject { |sub_exp| sub_exp.sexp_type == :void_stmt }
      end

      def wrap_in_block statements
        case statements.length
        when 0
          nil
        when 1
          statements.first
        else
          first = statements.shift
          if first.sexp_type == :block
            first.shift
            s(:block, *first, *statements)
          else
            s(:block, first, *statements)
          end
        end
      end

      def safe_wrap_in_block statements
        result = wrap_in_block statements
        result ? result : s()
      end

      def handle_return_argument_list arglist
        arglist = process(arglist)
        args = arglist[1..-1]

        if args.length == 1
          arg = args[0]
          if arg.sexp_type == :splat
            s(:svalue, arg)
          else
            arg
          end
        else
          s(:array, *args)
        end
      end

      def handle_array_elements elems
        elems = handle_potentially_typeless_sexp(elems)
        elems.map do |elem|
          if elem.first.is_a? Symbol
            elem
          else
            elem.first
          end
        end
      end
    end
  end
end
