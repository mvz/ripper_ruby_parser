module RipperRubyParser
  module SexpHandlers
    module Conditionals
      def process_if exp
        _, cond, truepart, falsepart = exp.shift 4

        s(:if, handle_condition(cond),
          wrap_in_block(map_body(truepart)),
          process(falsepart))
      end

      def process_elsif exp
        _, cond, truepart, falsepart = exp.shift 4

        s(:if, process(cond),
          wrap_in_block(map_body(truepart)),
          process(falsepart))
      end

      def process_if_mod exp
        _, cond, truepart = exp.shift 3
        s(:if, handle_condition(cond), process(truepart), nil)
      end

      def process_unless_mod exp
        _, cond, truepart = exp.shift 3
        s(:if, handle_condition(cond), nil, process(truepart))
      end

      def process_unless exp
        _, cond, truepart, falsepart = exp.shift 4
        s(:if,
          handle_condition(cond),
          process(falsepart),
          wrap_in_block(map_body(truepart)))
      end

      def process_case exp
        _, expr, clauses = exp.shift 3
        s(:case, process(expr), *process(clauses))
      end

      def process_when exp
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

        values = handle_array_elements values

        truepart = map_body(truepart)
        truepart = [nil] if truepart.empty?

        s(s(:when,
            s(:array, *values),
            *truepart),
          *falsepart)
      end

      def process_else exp
        _, body = exp.shift 2
        safe_wrap_in_block(map_body(body))
      end

      private

      def handle_condition(cond)
        cond = process(cond)
        if (cond.sexp_type == :lit) && cond[1].is_a?(Regexp)
          cond = s(:match, cond)
        elsif cond.sexp_type == :dot2
          cond = s(:flip2, *cond[1..-1])
        elsif cond.sexp_type == :dot3
          cond = s(:flip3, *cond[1..-1])
        end
        return cond
      end

    end
  end
end

