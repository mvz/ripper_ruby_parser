module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for operators
    module Operators
      BINARY_OPERATOR_MAP = {
        '&&': :and,
        '||': :or,
        and: :and,
        or: :or
      }.freeze

      UNARY_OPERATOR_MAP = {
        not: :!
      }.freeze

      NEGATED_BINARY_OPERATOR_MAP = {
        '!~': :=~
      }.freeze

      SHIFT_OPERATORS = [:<<, :>>].freeze

      def process_binary(exp)
        _, left, op, right = exp.shift 4

        if op == :=~
          make_regexp_match_operator(op, left, right)
        elsif (mapped = NEGATED_BINARY_OPERATOR_MAP[op])
          s(:not, make_regexp_match_operator(mapped, left, right))
        elsif (mapped = BINARY_OPERATOR_MAP[op])
          make_boolean_operator(mapped, left, right)
        elsif SHIFT_OPERATORS.include? op
          s(:call, process(left), op, process(right))
        else
          s(:call, handle_operator_argument(left), op, handle_operator_argument(right))
        end
      end

      def process_unary(exp)
        _, op, arg = exp.shift 3
        arg = handle_operator_argument(arg)
        op = UNARY_OPERATOR_MAP[op] || op
        s(:call, arg, op)
      end

      def process_dot2(exp)
        _, left, right = exp.shift 3
        left = process(left)
        right = process(right)
        if literal?(left) && literal?(right)
          s(:lit, Range.new(left[1], right[1]))
        else
          s(:dot2, left, right)
        end
      end

      def process_dot3(exp)
        _, left, right = exp.shift 3
        left = process(left)
        right = process(right)
        if literal?(left) && literal?(right)
          s(:lit, Range.new(left[1], right[1], true))
        else
          s(:dot3, left, right)
        end
      end

      def process_ifop(exp)
        _, cond, truepart, falsepart = exp.shift 4
        s(:if,
          handle_operator_argument(cond),
          handle_operator_argument(truepart),
          handle_operator_argument(falsepart))
      end

      private

      def make_boolean_operator(op, left, right)
        _, left, _, right = rebalance_binary(s(:binary, left, op, right))
        s(op, process(left), handle_operator_argument(right))
      end

      def make_regexp_match_operator(op, left, right)
        if left.sexp_type == :regexp_literal
          s(:match2, process(left), process(right))
        elsif right.sexp_type == :regexp_literal
          s(:match3, process(right), process(left))
        else
          s(:call, process(left), op, process(right))
        end
      end

      def rebalance_binary(exp)
        _, left, op, right = exp
        if left.sexp_type == :binary && BINARY_OPERATOR_MAP[op] == BINARY_OPERATOR_MAP[left[2]]
          _, left, _, middle = rebalance_binary(left)
          right = rebalance_binary(s(:binary, middle, op, right))
        end
        s(:binary, left, op, right)
      end

      def handle_operator_argument(exp)
        if exp.sexp_type == :begin
          s(:begin, process(exp))
        else
          process(exp)
        end
      end
    end
  end
end
