module RipperRubyParser
  module SexpHandlers
    module Assignment
      def process_assign exp
        _, lvalue, value = exp.shift 3

        lvalue = process(lvalue)
        value = process(value)

        with_line_number(lvalue.line,
                         create_regular_assignment_sub_type(lvalue, value))
      end

      def process_massign exp
        _, left, right = exp.shift 3

        left = handle_potentially_typeless_sexp left

        if left.first == :masgn
          left = left[1]
          left.shift
        end

        left = create_multiple_assignment_sub_types left

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

      def process_mlhs_paren exp
        _, contents = exp.shift 2

        items = handle_potentially_typeless_sexp(contents)

        return items if items.first.is_a? Symbol

        s(:masgn, s(:array, *create_multiple_assignment_sub_types(items)))
      end

      def process_opassign exp
        _, lvalue, operator, value = exp.shift 4

        lvalue = process(lvalue)
        value = process(value)
        operator = operator[1].gsub(/=/, '').to_sym

        create_operator_assignment_sub_type lvalue, value, operator
      end

      private

      def create_multiple_assignment_sub_types sexp_list
        sexp_list.map! do |item|
          if item.sexp_type == :splat
            if item[1].nil?
              s(:splat)
            else
              s(:splat, create_valueless_assignment_sub_type(item[1]))
            end
          else
            create_valueless_assignment_sub_type item
          end
        end
      end

      def create_valueless_assignment_sub_type(item)
        item = with_line_number(item.line,
                                create_regular_assignment_sub_type(item, nil))
        if item.sexp_type == :attrasgn
          item.last.pop
        else
          item.pop
        end
        return item
      end

      def create_operator_assignment_sub_type lvalue, value, operator
        case lvalue.sexp_type
        when :aref_field
          s(:op_asgn1, lvalue[1], s(:arglist, lvalue[2][1]), operator, value)
        when :field
          s(:op_asgn2, lvalue[1], :"#{lvalue[3][1]}=", operator, value)
        else
          if operator == :"||"
            s(:op_asgn_or, lvalue, create_assignment_sub_type(lvalue, value))
          else
            operator_call = s(:call, lvalue, operator, s(:arglist, value))
            create_assignment_sub_type lvalue, operator_call
          end
        end
      end

      def create_regular_assignment_sub_type lvalue, value
        case lvalue.sexp_type
        when :aref_field
          s(:attrasgn, lvalue[1], :[]=, s(:arglist, lvalue[2][1], value))
        when :field
          s(:attrasgn, lvalue[1], :"#{lvalue[3][1]}=", s(:arglist, value))
        else
          create_assignment_sub_type lvalue, value
        end
      end

      ASSIGNMENT_SUB_TYPE_MAP = {
        :ivar => :iasgn,
        :const => :cdecl,
        :lvar => :lasgn,
        :cvar => :cvdecl,
        :gvar => :gasgn
      }

      ASSIGNMENT_IN_METHOD_SUB_TYPE_MAP = {
        :cvar => :cvasgn
      }

      def create_assignment_sub_type lvalue, value
        s(map_assignment_lvalue_type(lvalue.sexp_type), lvalue[1], value)
      end

      def map_assignment_lvalue_type type
        @in_method_body && ASSIGNMENT_IN_METHOD_SUB_TYPE_MAP[type] ||
        ASSIGNMENT_SUB_TYPE_MAP[type] ||
        type
      end
    end
  end
end

