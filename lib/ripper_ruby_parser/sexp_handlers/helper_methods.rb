module RipperRubyParser
  module SexpHandlers
    # Utility methods used in several of the sexp handler modules
    module HelperMethods
      def handle_potentially_typeless_sexp(exp)
        if exp.first.is_a? Symbol
          process(exp)
        else
          exp.map! { |sub_exp| handle_potentially_typeless_sexp(sub_exp) }
        end
      end

      def handle_argument_list(exp)
        if exp.first.is_a? Symbol
          process(exp).tap(&:shift)
        else
          map_process exp
        end
      end

      def extract_node_symbol_with_position(exp)
        return nil if exp.nil?
        return exp if exp.is_a? Symbol

        _, ident, pos = exp.shift 3
        return ident.to_sym, pos
      end

      def extract_node_symbol(exp)
        return nil if exp.nil?
        _, ident, _ = exp.shift 3
        ident.to_sym
      end

      def with_position(pos, exp = nil)
        (line, _) = pos
        exp = yield if exp.nil?
        with_line_number line, exp
      end

      def with_line_number(line, exp)
        exp.line = line
        exp
      end

      def with_position_from_node_symbol(exp)
        sym, pos = extract_node_symbol_with_position exp
        with_position(pos, yield(sym))
      end

      def generic_add_star(exp)
        _, args, splatarg = exp.shift 3
        items = handle_potentially_typeless_sexp args
        items << s(:splat, process(splatarg))
        items << process(exp.shift) until exp.empty?
        items
      end

      def literal?(exp)
        exp.sexp_type == :lit
      end

      def map_body(body)
        map_process(body).reject { |sub_exp| sub_exp.sexp_type == :void_stmt }
      end

      def map_process(list)
        if list.sexp_type == :stmts
          list.sexp_body.map { |exp| process(exp) }
        else
          list.map  { |exp| process(exp) }
        end
      end

      def wrap_in_block(statements)
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

      def safe_wrap_in_block(statements)
        result = wrap_in_block statements
        result ? result : s()
      end

      def handle_return_argument_list(arglist)
        args = handle_potentially_typeless_sexp(arglist)
        args.shift if args.sexp_type == :arglist

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

      def handle_array_elements(elems)
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
