module RipperRubyParser
  module SexpHandlers
    module Loops
      def process_until exp
        _, cond, block = exp.shift 3

        make_until(process(cond), handle_statement_list(block), true)
      end

      def process_until_mod exp
        _, cond, block = exp.shift 3

        check_at_start = check_at_start?(block)

        make_until(process(cond), process(block), check_at_start)
      end

      def process_while exp
        _, cond, block = exp.shift 3

        make_while(process(cond), handle_statement_list(block), true)
      end

      def process_while_mod exp
        _, cond, block = exp.shift 3

        check_at_start = check_at_start?(block)

        make_while(process(cond), process(block), check_at_start)
      end

      def process_for exp
        _, var, coll, block = exp.shift 4
        s(:for, process(coll),
          s(:lasgn, process(var)[1]),
          handle_statement_list(block))
      end

      private

      def make_until(cond, block, check_at_start)
        s(:until, cond, block, check_at_start)
      end

      def make_while(cond, block, check_at_start)
        s(:while, cond, block, check_at_start)
      end

      def check_at_start?(block)
        block.sexp_type != :begin
      end
    end
  end
end

