module RipperRubyParser
  module SexpHandlers
    module Conditionals
      def process_if exp
        _, cond, truepart, falsepart = exp.shift 4

        cond = process(cond)
        truepart = handle_statement_list(truepart)
        falsepart = process(falsepart)

        if cond.sexp_type == :not
          cond = cond[1]
          truepart, falsepart = falsepart, truepart
        end

        s(:if, cond, truepart, falsepart)
      end

      def process_elsif exp
        _, cond, truepart, falsepart = exp.shift 4

        s(:if, process(cond),
          handle_statement_list(truepart),
          process(falsepart))
      end

      def process_if_mod exp
        _, cond, truepart = exp.shift 3
        process_if s(:if, cond, s(truepart), nil)
      end

      def process_unless_mod exp
        _, cond, truepart = exp.shift 3
        s(:if, process(cond), nil, process(truepart))
      end

      def process_unless exp
        _, cond, truepart, falsepart = exp.shift 4
        s(:if,
          process(cond),
          process(falsepart),
          handle_statement_list(truepart))
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

        values = handle_array_elements values
        values = values.map do |val|
          if val.sexp_type == :splat
            s(:when, val[1], nil)
          else
            val
          end
        end

        s(s(:when,
            s(:array, *values),
            *map_body(truepart)),
          *falsepart)
      end

      def process_else exp
        _, body = exp.shift 2
        handle_statement_list body
      end
    end
  end
end

