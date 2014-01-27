module RipperRubyParser
  module SexpHandlers
    module MethodCalls
      def process_method_add_arg exp
        _, call, parens = exp.shift 3
        call = process(call)
        unless parens.empty?
          parens = process(parens)
          parens.shift
        end
        parens.each do |arg|
          call << arg
        end
        call
      end

      def process_call exp
        _, receiver, _, ident = exp.shift 4
        with_position_from_node_symbol(ident) {|method|
          s(:call, process(receiver), method) }
      end

      def process_command exp
        _, ident, arglist = exp.shift 3
        with_position_from_node_symbol(ident) {|method|
          args = handle_potentially_typeless_sexp_with_fallback_type(:arglist, arglist)
          args.shift
          s(:call, nil, method, *args)
        }
      end

      def process_command_call exp
        _, receiver, _, ident, arguments = exp.shift 5
        with_position_from_node_symbol(ident) {|method|
          args = handle_potentially_typeless_sexp_with_fallback_type(:arglist, arguments)
          args.shift
          s(:call, process(receiver), method, *args)
        }
      end

      def process_vcall exp
        _, ident = exp.shift 2
        with_position_from_node_symbol(ident) {|method|
          s(:call, nil, method) }
      end

      def process_fcall exp
        _, ident = exp.shift 2
        with_position_from_node_symbol(ident) {|method|
          s(:call, nil, method) }
      end

      def process_super exp
        _, args = exp.shift 2
        args = process(args)
        args.shift
        s(:super, *args)
      end
    end
  end
end

