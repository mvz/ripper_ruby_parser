module RipperRubyParser
  module SexpHandlers
    module Conditionals
      def process_if exp
        _, cond, truepart, falsepart = exp.shift 4
        s(:if,
          process(cond),
          handle_statement_list(truepart),
          process(falsepart))
      end

      def process_unless_mod exp
        _, cond, truepart = exp.shift 3
        s(:if, process(cond), nil, process(truepart))
      end

      def process_unless exp
        _, cond, truepart, _ = exp.shift 4
        s(:if, process(cond), nil, handle_statement_list(truepart))
      end

      def process_case exp
        _, expr, clauses = exp.shift 3
        s(:case, process(expr), *process(clauses))
      end

      def process_when exp
        _, values, truepart, falsepart = exp.shift 4
        falsepart = falsepart.nil? ? [nil] : process(falsepart)
        s(s(:when,
            process(s(:array, values)),
            handle_statement_list(truepart)),
          *falsepart)
      end

      def process_else exp
        _, body = exp.shift 2
        handle_statement_list body
      end
    end
  end
end

