# frozen_string_literal: true

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
          make_regexp_match_operator(left, op, right)
        elsif (mapped = NEGATED_BINARY_OPERATOR_MAP[op])
          s(:not, make_regexp_match_operator(left, mapped, right))
        elsif (mapped = BINARY_OPERATOR_MAP[op])
          make_boolean_operator(left, mapped, right)
        elsif SHIFT_OPERATORS.include? op
          s(:call, unwrap_begin(process(left)), op, unwrap_begin(process(right)))
        else
          s(:call, process(left), op, process(right))
        end
      end

      def process_unary(exp)
        _, op, arg = exp.shift 3
        arg = process(arg)
        op = UNARY_OPERATOR_MAP[op] || op
        s(:call, arg, op)
      end

      def process_dot2(exp)
        _, left, right = exp.shift 3
        left = process(left)
        right = process(right)
        if integer_literal?(left) && integer_literal?(right)
          s(:lit, Range.new(left[1], right[1]))
        else
          s(:dot2, left, right)
        end
      end

      def process_dot3(exp)
        _, left, right = exp.shift 3
        left = process(left)
        right = process(right)
        if integer_literal?(left) && integer_literal?(right)
          s(:lit, Range.new(left[1], right[1], true))
        else
          s(:dot3, left, right)
        end
      end

      def process_ifop(exp)
        _, cond, truepart, falsepart = exp.shift 4
        s(:if,
          process(cond),
          process(truepart),
          process(falsepart))
      end

      private

      def make_boolean_operator(left, operator, right)
        _, left, _, right = rebalance_binary(left, operator, right)
        s(operator, unwrap_begin(process(left)), process(right))
      end

      def make_regexp_match_operator(left, operator, right)
        if left.sexp_type == :regexp_literal
          s(:match2, process(left), process(right))
        elsif right.sexp_type == :regexp_literal
          s(:match3, process(right), process(left))
        else
          s(:call, process(left), operator, process(right))
        end
      end

      def rebalance_binary(left, operator, right)
        if BINARY_OPERATOR_MAP[operator] == BINARY_OPERATOR_MAP[left[2]]
          _, left, _, middle = rebalance_binary(*left.sexp_body)
          right = rebalance_binary(middle, operator, right)
        end
        s(:binary, left, operator, right)
      end
    end
  end
end
