module RipperRubyParser
  module SexpHandlers
    module Loops
      def process_until exp
        handle_conditional_loop(:until, exp)
      end

      def process_until_mod exp
        handle_conditional_loop_mod(:until, exp)
      end

      def process_while exp
        handle_conditional_loop(:while, exp)
      end

      def process_while_mod exp
        handle_conditional_loop_mod(:while, exp)
      end

      def process_for exp
        _, var, coll, block = exp.shift 4
        coll = process(coll)
        assgn = s(:lasgn, process(var)[1])
        block = wrap_in_block(map_body(block))
        if block.nil?
          s(:for, coll, assgn)
        else
          s(:for, coll, assgn, block)
        end
      end

      private

      def check_at_start? block
        block.sexp_type != :begin
      end

      def handle_conditional_loop type, exp
        _, cond, block = exp.shift 3

        s(type, process(cond), wrap_in_block(map_body(block)), true)
      end

      def handle_conditional_loop_mod type, exp
        _, cond, block = exp.shift 3

        check_at_start = check_at_start?(block)

        s(type, process(cond), process(block), check_at_start)
      end

    end
  end
end
