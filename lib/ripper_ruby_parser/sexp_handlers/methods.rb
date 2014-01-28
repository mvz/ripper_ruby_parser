module RipperRubyParser
  module SexpHandlers
    module Methods
      def process_def exp
        _, ident, params, body = exp.shift 4
        ident, pos = extract_node_symbol_with_position ident
        params = convert_special_args(process(params))
        with_position(pos,
                      s(:defn, ident, params, *method_body(body)))
      end

      def process_defs exp
        _, receiver, _, method, params, body = exp.shift 6
        params = convert_special_args(process(params))

        body = in_method do
          scope = process(body)
          block = scope[1]
          block.shift
          block
        end

        s(:defs,
          process(receiver),
          extract_node_symbol(method),
          params, *body)
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

      def in_method
        @in_method_body = true
        result = yield
        @in_method_body = false
        result
      end

      def make_method_name_literal exp
        process(exp).tap {|it| it[0] = :lit}
      end

      def method_body exp
        scope = in_method { process exp }
        block = scope[1]
        if block.length == 1
          block.push s(:nil)
        end
        block.shift
        block
      end

      SPECIAL_ARG_MARKER = {
        :splat => "*",
        :blockarg => "&"
      }

      def convert_special_args args
        args.map! do |item|
          if item.is_a? Symbol
            item
          else
            if (marker = SPECIAL_ARG_MARKER[item.sexp_type])
              name = extract_node_symbol item[1]
              :"#{marker}#{name}"
            elsif item.sexp_type == :lvar
              item[1]
            else
              item
            end
          end
        end
      end
    end
  end
end
