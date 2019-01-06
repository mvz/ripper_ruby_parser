# frozen_string_literal: true

module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for conditionals
    module Conditionals
      def process_if(exp)
        _, cond, truepart, falsepart = exp.shift 4

        construct_conditional(handle_condition(cond),
                              handle_consequent(truepart),
                              handle_consequent(falsepart))
      end

      def process_elsif(exp)
        _, cond, truepart, falsepart = exp.shift 4

        s(:if,
          unwrap_begin(process(cond)),
          handle_consequent(truepart),
          handle_consequent(falsepart))
      end

      def process_if_mod(exp)
        _, cond, truepart = exp.shift 3

        construct_conditional(handle_condition(cond),
                              process(truepart),
                              nil)
      end

      def process_unless(exp)
        _, cond, truepart, falsepart = exp.shift 4

        construct_conditional(handle_condition(cond),
                              handle_consequent(falsepart),
                              handle_consequent(truepart))
      end

      def process_unless_mod(exp)
        _, cond, truepart = exp.shift 3

        construct_conditional(handle_condition(cond),
                              nil,
                              process(truepart))
      end

      def process_case(exp)
        _, expr, clauses = exp.shift 3
        s(:case, process(expr), *process(clauses))
      end

      def process_when(exp)
        _, values, truepart, falsepart = exp.shift 4

        falsepart = process(falsepart)
        falsepart = unwrap_nil falsepart if falsepart

        if falsepart.nil?
          falsepart = [nil]
        elsif falsepart.first.is_a? Symbol
          falsepart = s(falsepart)
        end

        values = process(values).sexp_body

        truepart = map_process_list_compact truepart.sexp_body
        truepart = [nil] if truepart.empty?

        s(s(:when,
            s(:array, *values),
            *truepart),
          *falsepart)
      end

      def process_else(exp)
        _, body = exp.shift 2
        process(body)
      end

      private

      def handle_condition(cond)
        cond = unwrap_begin process(cond)
        case cond.sexp_type
        when :lit
          return s(:match, cond) if cond.last.is_a?(Regexp)
        when :dot2
          return s(:flip2, *cond.sexp_body)
        when :dot3
          return s(:flip3, *cond.sexp_body)
        end
        cond
      end

      def handle_consequent(exp)
        unwrap_nil process(exp) if exp
      end

      def construct_conditional(cond, truepart, falsepart)
        if cond.sexp_type == :not
          _, inner = cond
          s(:if, inner, falsepart, truepart)
        else
          s(:if, cond, truepart, falsepart)
        end
      end
    end
  end
end
