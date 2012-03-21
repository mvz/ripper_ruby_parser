module RipperRubyParser
  module SexpHandlers
    module Methods
      def process_def exp
        _, ident, params, body = exp.shift 4
        ident, pos = extract_node_symbol_with_position ident
        with_position(pos,
                      s(:defn, ident, process(params), method_body(body)))
      end

      def process_defs exp
        _, receiver, _, method, args, body = exp.shift 6
        s(:defs, process(receiver),
          extract_node_symbol(method),
          process(args), process(body))
      end

      def process_return exp
        _, arglist = exp.shift 2
        s(:return, handle_return_argument_list(arglist))
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

      def process_undef exp
        _, args = exp.shift 2

        args.map! do |sub_exp|
          s(:undef, make_method_name_literal(sub_exp))
        end

        if args.size == 1
          args[0]
        else
          s(:block, *args)
        end
      end

      def process_alias exp
        _, *args = exp.shift 3

        args.map! do |sub_exp|
          make_method_name_literal sub_exp
        end

        s(:alias, *args)
      end

      private

      def make_method_name_literal exp
        process(exp).tap {|it| it[0] = :lit}
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
