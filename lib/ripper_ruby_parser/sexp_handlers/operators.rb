# frozen_string_literal: true

module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for operators
    module Operators
      BINARY_OPERATOR_MAP = {
        "&&": :and,
        "||": :or,
        and: :and,
        or: :or
      }.freeze

      BINARY_LOGICAL_OPERATORS = BINARY_OPERATOR_MAP.keys.freeze

      UNARY_OPERATOR_MAP = {
        not: :!
      }.freeze

      SHIFT_OPERATORS = [:<<, :>>].freeze

      def process_binary(exp)
        _, left, op, right = exp.shift 4

        case op
        when :=~
          make_regexp_match_operator(left, op, right)
        when :!~
          s(:not, make_regexp_match_operator(left, :=~, right))
        when *BINARY_LOGICAL_OPERATORS
          make_boolean_operator(left, op, right)
        when *SHIFT_OPERATORS
          s(:call, unwrap_begin(process(left)), op, unwrap_begin(process(right)))
        when :"=>"
          make_rightward_assignment(left, right)
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
          with_line_number(left.line, s(:lit, Range.new(left[1], right[1])))
        else
          s(:dot2, left, right)
        end
      end

      def process_dot3(exp)
        _, left, right = exp.shift 3
        left = process(left)
        right = process(right)
        if integer_literal?(left) && integer_literal?(right)
          with_line_number(left.line, s(:lit, Range.new(left[1], right[1], true)))
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
        operator = BINARY_OPERATOR_MAP[operator]
        _, left, _, right = rebalance_binary(left, operator, right)
        s(operator, unwrap_begin(process(left)), process(right))
      end

      def make_regexp_match_operator(left, operator, right)
        left = process(left)
        right = process(right)

        if regexp? left
          s(:match2, left, right)
        elsif regexp? right
          s(:match3, right, left)
        else
          s(:call, left, operator, right)
        end
      end

      def regexp?(exp)
        exp.sexp_type == :dregx ||
          exp.sexp_type == :lit && exp.sexp_body.first.is_a?(Regexp)
      end

      def make_rightward_assignment(left, right)
        s(:lasgn, process(right)[1], process(left))
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
