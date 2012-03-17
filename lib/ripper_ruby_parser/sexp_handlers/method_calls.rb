module RipperRubyParser
  module SexpHandlers
    module MethodCalls
      def process_method_add_arg exp
        _, call, parens = exp.shift 3
        call = process call
        args = if parens.empty?
                 s(:arglist)
               else
                 process parens
               end
        with_position(call.line,
                      s(:call, call[1], call[2], args))
      end

      def process_call exp
        _, receiver, _, method = exp.shift 4
        s(:call, process(receiver), extract_node_symbol(method), s(:arglist))
      end

      def process_command exp
        _, ident, arglist = exp.shift 3

        ident = extract_node_symbol ident
        arglist = process arglist

        s(:call, nil, ident, arglist)
      end

      def process_command_call exp
        _, receiver, _, method, arguments = exp.shift 5
        s(:call,
          process(receiver),
          extract_node_symbol(method),
          process(arguments))
      end

      def process_vcall exp
        _, ident = exp.shift 2

        ident, pos = extract_node_symbol_with_position ident

        with_position(pos,
                      s(:call, nil, ident, s(:arglist)))
      end

      def process_fcall exp
        _, method = exp.shift 2
        method, pos = extract_node_symbol_with_position method
        with_position(pos,
                      s(:call, nil, method, s(:arglist)))
      end
    end
  end
end

