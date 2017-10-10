module RipperRubyParser
  module SexpHandlers
    # Utility methods used in several of the sexp handler modules
    module HelperMethods
      def handle_argument_list(exp)
        process(exp).tap(&:shift)
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
        items = process args
        items << s(:splat, process(splatarg))
        items << process(exp.shift) until exp.empty?
        items
      end

      def literal?(exp)
        exp.sexp_type == :lit
      end

      def reject_void_stmt(body)
        body.reject { |sub_exp| sub_exp.sexp_type == :void_stmt }
      end

      def map_process_sexp_body_compact(list)
        reject_void_stmt map_process_sexp_body list
      end

      def map_process_sexp_body(list)
        map_process_list(list.sexp_body)
      end

      def map_process_list(list)
        list.map { |exp| process(exp) }
      end

      def unwrap_nil(exp)
        if exp.sexp_type == :void_stmt
          nil
        else
          exp
        end
      end

      def safe_unwrap_void_stmt(exp)
        unwrap_nil(exp) || s()
      end

      def handle_return_argument_list(arglist)
        args = process(arglist)
        args.shift if [:arglist, :args].include? args.sexp_type

        case args.length
        when 0
          s()
        when 1
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
        process(elems).sexp_body
      end
    end
  end
end
