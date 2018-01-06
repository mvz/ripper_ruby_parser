module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for assignments
    module Assignment
      def process_assign(exp)
        _, lvalue, value = exp.shift 3
        lvalue = process(lvalue)
        value = process(value)

        case value.sexp_type
        when :mrhs
          value.sexp_type = :svalue
        when :fake_array
          value = s(:svalue, s(:array, *value.sexp_body))
        end

        with_line_number(lvalue.line,
                         create_regular_assignment_sub_type(lvalue, value))
      end

      def process_massign(exp)
        _, left, right = exp.shift 3

        left = process left

        left = left[1] if left.sexp_type == :masgn
        left = create_multiple_assignment_sub_types left.sexp_body

        right = process(right)

        case right.sexp_type
        when :fake_array
          right[0] = :array
        when :mrhs
          right = right[1]
        else
          right = s(:to_ary, right)
        end

        s(:masgn, s(:array, *left), right)
      end

      def process_mrhs_new_from_args(exp)
        _, inner, last = exp.shift 3
        inner = map_process_sexp_body_compact(inner)
        inner.push process(last) if last
        s(:fake_array, *inner)
      end

      def process_mrhs_add_star(exp)
        generic_add_star exp
      end

      def process_mlhs_add_star(exp)
        _, args, splatarg = exp.shift 3
        items = process args
        items << s(:splat, process(splatarg))
      end

      def process_mlhs_add_post(exp)
        _, base, rest = exp.shift 3
        process(base).push(*process(rest).sexp_body)
      end

      def process_mlhs_paren(exp)
        _, contents = exp.shift 2

        items = process(contents)

        if items.sexp_type == :mlhs
          s(:masgn, s(:array, *create_multiple_assignment_sub_types(items.sexp_body)))
        else
          items
        end
      end

      def process_opassign(exp)
        _, lvalue, operator, value = exp.shift 4

        lvalue = process(lvalue)
        value = process(value)
        operator = operator[1].delete('=').to_sym

        create_operator_assignment_sub_type lvalue, value, operator
      end

      private

      def create_multiple_assignment_sub_types(sexp_list)
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
        item.pop
        item
      end

      OPERATOR_ASSIGNMENT_MAP = {
        '||': :op_asgn_or,
        '&&': :op_asgn_and
      }.freeze

      def create_operator_assignment_sub_type(lvalue, value, operator)
        case lvalue.sexp_type
        when :aref_field
          _, arr, arglist = lvalue
          s(:op_asgn1, arr, arglist, operator, value)
        when :field
          _, obj, _, (_, field) = lvalue
          s(:op_asgn2, obj, :"#{field}=", operator, value)
        else
          if (mapped = OPERATOR_ASSIGNMENT_MAP[operator])
            s(mapped, lvalue, create_assignment_sub_type(lvalue, value))
          else
            operator_call = s(:call, lvalue, operator, value)
            create_assignment_sub_type lvalue, operator_call
          end
        end
      end

      def create_regular_assignment_sub_type(lvalue, value)
        case lvalue.sexp_type
        when :aref_field
          _, arr, arglist = lvalue
          arglist << value
          arglist.shift
          s(:attrasgn, arr, :[]=, *arglist)
        when :field
          _, obj, _, (_, field) = lvalue
          s(:attrasgn, obj, :"#{field}=", value)
        else
          create_assignment_sub_type lvalue, value
        end
      end

      ASSIGNMENT_SUB_TYPE_MAP = {
        ivar: :iasgn,
        const: :cdecl,
        lvar: :lasgn,
        cvar: :cvdecl,
        gvar: :gasgn
      }.freeze

      ASSIGNMENT_IN_METHOD_SUB_TYPE_MAP = {
        cvar: :cvasgn
      }.freeze

      def create_assignment_sub_type(lvalue, value)
        s(map_assignment_lvalue_type(lvalue.sexp_type), lvalue[1], value)
      end

      def map_assignment_lvalue_type(type)
        @in_method_body && ASSIGNMENT_IN_METHOD_SUB_TYPE_MAP[type] ||
          ASSIGNMENT_SUB_TYPE_MAP[type] ||
          type
      end
    end
  end
end
