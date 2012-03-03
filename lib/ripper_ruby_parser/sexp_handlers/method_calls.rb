module RipperRubyParser
  module SexpHandlers
    module MethodCalls
      def process_method_add_arg exp
        _, call, parens = exp.shift 3
        call = process call
        s(:call, call[1], call[2], process(parens))
      end

      def process_command_call exp
        _, receiver, _, method, arguments = exp.shift 5
        s(:call,
          process(receiver),
          identifier_node_to_symbol(method),
          process(arguments))
      end

      def process_fcall exp
        _, method = exp.shift 2
        s(:call, nil, identifier_node_to_symbol(method), s(:arglist))
      end
    end
  end
end

