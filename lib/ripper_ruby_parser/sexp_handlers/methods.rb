module RipperRubyParser
  module SexpHandlers
    module Methods
      def process_def exp
        _, ident, params, body = exp.shift 4
        ident = identifier_node_to_symbol ident
        s(:defn, ident, process(params), method_body(body))
      end

      def process_defs exp
        _, reciever, _, method, args, body = exp.shift 6
        s(:defs, process(reciever),
          identifier_node_to_symbol(method),
          process(args), process(body))
      end
    end
  end
end
