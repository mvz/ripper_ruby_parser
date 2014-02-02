module RipperRubyParser
  module SexpHandlers
    module Operators
      BINARY_OPERATOR_MAP = {
        :"&&" => :and,
        :"||" => :or,
        :and => :and,
        :or => :or
      }

      UNARY_OPERATOR_MAP = {
        :not => :!
      }

      NEGATED_BINARY_OPERATOR_MAP = {
        :"!~" => :=~,
      }

      def process_binary exp
        _, left, op, right = exp.shift 4

        if op == :=~
          make_regexp_match_operator(op, left, right)
        elsif (mapped = NEGATED_BINARY_OPERATOR_MAP[op])
          s(:not, make_regexp_match_operator(mapped, left, right))
        elsif (mapped = BINARY_OPERATOR_MAP[op])
          make_boolean_operator(mapped, left, right)
        else
          s(:call, process(left), op, process(right))
        end
      end

      def make_boolean_operator(op, left, right)
        if left.first == :paren
          s(op, process(left), process(right))
        else
          rebalance_binary(s(op, process(left), process(right)))
        end
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

      def process_unary exp
        _, op, arg = exp.shift 3
        arg = process(arg)
        op = UNARY_OPERATOR_MAP[op] || op
        if is_literal?(arg) && op != :!
          s(:lit, arg[1].send(op))
        else
          s(:call, arg, op)
        end
      end

      def process_dot2 exp
        _, left, right = exp.shift 3
        left = process(left)
        right = process(right)
        if is_literal?(left) && is_literal?(right)
          s(:lit, Range.new(left[1], right[1]))
        else
          s(:dot2, left, right)
        end
      end

      def process_dot3 exp
        _, left, right = exp.shift 3
        left = process(left)
        right = process(right)
        if is_literal?(left) && is_literal?(right)
          s(:lit, Range.new(left[1], right[1], true))
        else
          s(:dot3, left, right)
        end
      end

      def process_ifop exp
        _, cond, truepart, falsepart = exp.shift 4
        s(:if, process(cond), process(truepart), process(falsepart))
      end

      private

      def rebalance_binary exp
        op, left, right = exp

        if op == left.sexp_type
          s(op, left[1], rebalance_binary(s(op, left[2], right)))
        else
          s(op, left, right)
        end
      end
    end
  end
end
