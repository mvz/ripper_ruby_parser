module RipperRubyParser
  module SexpHandlers
    module Methods
      def process_def exp
        _, ident, params, body = exp.shift 4
        ident = extract_node_symbol ident
        s(:defn, ident, process(params), method_body(body))
      end

      def process_defs exp
        _, receiver, _, method, args, body = exp.shift 6
        s(:defs, process(receiver),
          extract_node_symbol(method),
          process(args), process(body))
      end

      def process_return exp
        _, arglist = exp.shift 2

        arglist = process(arglist)
        args = arglist[1..-1]

        if args.length == 1
          arg = args[0]
          if arg.sexp_type == :splat
            s(:return, s(:svalue, arg))
          else
            s(:return, arg)
          end
        else
          s(:return, s(:array, *args))
        end
      end

      def process_return0 exp
        _ = exp.shift
        s(:return)
      end

      def process_yield exp
        _, arglist = exp.shift 2
        arglist = process arglist
        s(:yield, *arglist[1..-1])
      end

      def process_yield0 exp
        _ = exp.shift
        s(:yield)
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
