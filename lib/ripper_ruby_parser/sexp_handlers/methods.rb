module RipperRubyParser
  module SexpHandlers
    module Methods
      def process_def exp
        _, ident, params, body = exp.shift 4
        ident = identifier_node_to_symbol ident
        s(:defn, ident, process(params), method_body(body))
      end

      def process_defs exp
        _, receiver, _, method, args, body = exp.shift 6
        s(:defs, process(receiver),
          identifier_node_to_symbol(method),
          process(args), process(body))
      end

      def process_return exp
        _, arglist = exp.shift 2
        arglist = process(arglist)
        s(:return, arglist[1])
      end

      def process_return0 exp
        _ = exp.shift
        s(:return)
      end

      def method_body exp
        scope = process exp
        block = scope[1]
        if block.length == 1
          block.push s(:nil)
        end
        scope
      end
    end
  end
end
