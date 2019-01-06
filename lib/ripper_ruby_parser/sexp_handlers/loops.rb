# frozen_string_literal: true

module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for loops
    module Loops
      def process_until(exp)
        handle_conditional_loop :until, :while, exp
      end

      def process_until_mod(exp)
        handle_conditional_loop_mod :until, :while, exp
      end

      def process_while(exp)
        handle_conditional_loop :while, :until, exp
      end

      def process_while_mod(exp)
        handle_conditional_loop_mod :while, :until, exp
      end

      def process_for(exp)
        _, var, coll, block = exp.shift 4
        coll = process(coll)
        var = process(var)

        var.sexp_type = :lasgn if var.sexp_type == :lvar
        block = unwrap_nil process(block)
        if block
          s(:for, coll, var, block)
        else
          s(:for, coll, var)
        end
      end

      private

      def check_at_start?(block)
        block.sexp_type != :begin
      end

      def handle_conditional_loop(type, negated_type, exp)
        _, cond, body = exp.shift 3

        construct_conditional_loop(type, negated_type,
                                   unwrap_begin(process(cond)),
                                   unwrap_nil(process(body)),
                                   true)
      end

      def handle_conditional_loop_mod(type, negated_type, exp)
        _, cond, body = exp.shift 3

        check_at_start = check_at_start?(body)
        construct_conditional_loop(type, negated_type,
                                   unwrap_begin(process(cond)),
                                   unwrap_begin(process(body)),
                                   check_at_start)
      end

      def construct_conditional_loop(type, negated_type, cond, body, check_at_start)
        if cond.sexp_type == :not
          _, inner = cond
          s(negated_type, inner, body, check_at_start)
        else
          s(type, cond, body, check_at_start)
        end
      end
    end
  end
end
