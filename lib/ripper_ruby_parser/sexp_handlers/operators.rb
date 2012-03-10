module RipperRubyParser
  module SexpHandlers
    module Operators
      OPERATOR_MAP = {
        "&&".to_sym => :and,
        "||".to_sym => :or
      }

      def process_binary exp
        _, left, op, right = exp.shift 4
        mapped = OPERATOR_MAP[op]
        if mapped
          s(mapped, process(left), process(right))
        else
          s(:call, process(left), op, s(:arglist, process(right)))
        end
      end

      def process_unary exp
        _, _, arg = exp.shift 3
        arg = process(arg)
        case arg.sexp_type
        when :lit
          s(:lit, -arg[1])
        else
          s(:call, arg, :-@, s(:arglist))
        end
      end
      end
    end
  end
end
