module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for conditionals
    module Conditionals
      def process_if(exp)
        _, cond, truepart, falsepart = exp.shift 4

        construct_conditional(handle_condition(cond),
                              wrap_in_block(map_process_sexp_body_compact(truepart)),
                              process(falsepart))
      end

      def process_elsif(exp)
        _, cond, truepart, falsepart = exp.shift 4

        s(:if, process(cond),
          wrap_in_block(map_process_sexp_body_compact(truepart)),
          process(falsepart))
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
                              process(falsepart),
                              wrap_in_block(map_process_sexp_body_compact(truepart)))
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

        if falsepart.nil?
          falsepart = [nil]
        else
          falsepart = process(falsepart)
          if falsepart.first.is_a? Symbol
            falsepart = s(falsepart)
          end
        end
        falsepart = [nil] if falsepart.empty?

        values = handle_argument_list values

        truepart = map_process_sexp_body_compact(truepart)
        truepart = [nil] if truepart.empty?

        s(s(:when,
            s(:array, *values),
            *truepart),
          *falsepart)
      end

      def process_else(exp)
        _, body = exp.shift 2
        safe_wrap_in_block(map_process_sexp_body_compact(body))
      end

      private

      def handle_condition(cond)
        cond = process(cond)
        if (cond.sexp_type == :lit) && cond[1].is_a?(Regexp)
          s(:match, cond)
        elsif cond.sexp_type == :dot2
          s(:flip2, *cond[1..-1])
        elsif cond.sexp_type == :dot3
          s(:flip3, *cond[1..-1])
        else
          cond
        end
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
