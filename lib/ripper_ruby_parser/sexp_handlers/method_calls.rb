module RipperRubyParser
  module SexpHandlers
    module MethodCalls
      def process_method_add_arg exp
        _, call, parens = exp.shift 3
        call = process(call)
        call[3] = process(parens) unless parens.empty?
        call
      end

      def process_call exp
        _, receiver, _, ident = exp.shift 4
        with_position_from_node_symbol(ident) {|method|
          s(:call, process(receiver), method, s(:arglist)) }
      end

      def process_command exp
        _, ident, arglist = exp.shift 3
        with_position_from_node_symbol(ident) {|method|
          s(:call, nil, method,
            handle_potentially_typeless_sexp_with_fallback_type(:arglist, arglist))
        }
      end

      def process_command_call exp
        _, receiver, _, ident, arguments = exp.shift 5
        with_position_from_node_symbol(ident) {|method|
          s(:call, process(receiver), method,
            handle_potentially_typeless_sexp_with_fallback_type(:arglist, arguments))
        }
      end

      def process_vcall exp
        _, ident = exp.shift 2
        with_position_from_node_symbol(ident) {|method|
          s(:call, nil, method, s(:arglist)) }
      end

      def process_fcall exp
        _, ident = exp.shift 2
        with_position_from_node_symbol(ident) {|method|
          s(:call, nil, method, s(:arglist)) }
      end
    end
  end
end

