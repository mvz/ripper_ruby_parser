module RipperRubyParser
  module SexpHandlers
    module Assignment
      def process_massign exp
        _, left, right = exp.shift 3

        left = handle_list_with_optional_splat left

        left.each do |item|
          case item.sexp_type
          when :splat
            item[1][0] = :lasgn
          else
            item[0] = :lasgn
          end
        end

        right = process(right)

        unless right.sexp_type == :array
          right = s(:to_ary, right)
        end

        s(:masgn, s(:array, *left), right)
      end

      def process_mrhs_new_from_args exp
        _, inner, last = exp.shift 3
        inner.map! {|item| process(item)}
        inner.push process(last)
        s(:array, *inner)
      end

      def process_mlhs_add_star exp
        generic_add_star exp
      end
    end
  end
end

