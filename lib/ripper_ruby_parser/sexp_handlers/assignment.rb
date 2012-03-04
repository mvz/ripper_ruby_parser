module RipperRubyParser
  module SexpHandlers
    module Assignment
      def process_massign exp
        _, left, right = exp.shift 3

        left.map! do |item|
          process(item).tap {|it| it[0] = :lasgn }
        end

        s(:masgn, s(:array, *left), process(right))
      end

      def process_mrhs_new_from_args exp
        _, inner, last = exp.shift 3
        inner.map! {|item| process(item)}
        inner.push process(last)
        s(:array, *inner)
      end
    end
  end
end

