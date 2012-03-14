module RipperRubyParser
  module SexpHandlers
    module Assignment
      def process_assign exp
        _, lvalue, value = exp.shift 3

        lvalue = process(lvalue)
        value = process(value)

        create_assignment_sub_type lvalue, value
      end

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

      def process_opassign exp
        _, lvalue, operator, value = exp.shift 4

        lvalue = process(lvalue)
        value = process(value)
        operator = operator[1].gsub(/=/, '').to_sym
        operator_call = s(:call, lvalue, operator, s(:arglist, value))

        case lvalue.sexp_type
        when :ivar
          s(:iasgn, lvalue[1], operator_call)
        when :aref_field
          s(:op_asgn1, lvalue[1], s(:arglist, lvalue[2][1]), operator, value)
        else
          s(:lasgn, lvalue[1], operator_call)
        end
      end

      def create_assignment_sub_type lvalue, value
        case lvalue.sexp_type
        when :ivar
          s(:iasgn, lvalue[1], value)
        when :aref_field
          s(:attrasgn, lvalue[1], :[]=, s(:arglist, lvalue[2][1], value))
        when :const
          s(:cdecl, lvalue[1], value)
        when :lvar
          s(:lasgn, lvalue[1], value)
        when :field
          s(:attrasgn, lvalue[1], :"#{lvalue[3][1]}=", s(:arglist, value))
        when :cvar
          s(:cvdecl, lvalue[1], value)
        when :gvar
          s(:gasgn, lvalue[1], value)
        else
          s(lvalue.sexp_type, lvalue[1], value)
        end
      end
    end
  end
end

