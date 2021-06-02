# frozen_string_literal: true

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
        when :args
          value = s(:svalue, s(:array, *value.sexp_body))
        else
          value = unwrap_begin(value)
        end

        with_line_number(lvalue.line,
                         create_regular_assignment_sub_type(lvalue, value))
      end

      def process_massign(exp)
        _, left, right = exp.shift 3

        left = process(left).last
        right = process(right)

        case right.sexp_type
        when :args
          right.sexp_type = :array
        when :mrhs
          _, right = right
        else
          right = s(:to_ary, unwrap_begin(right))
        end

        s(:masgn, left, right)
      end

      def process_mrhs_new_from_args(exp)
        _, inner, last = exp.shift 3
        process(inner).tap do |result|
          result.push process(last) if last
        end
      end

      def process_mrhs_add_star(exp)
        generic_add_star exp
      end

      def process_mlhs_add_star(exp)
        _, base, splatarg = exp.shift 3
        masgn = process base

        splat = process(splatarg)
        splat_item = if splat.nil?
                       s(:splat)
                     else
                       s(:splat, create_valueless_assignment_sub_type(splat))
                     end

        masgn.last << splat_item
        masgn
      end

      def process_mlhs_add_post(exp)
        _, base, rest = exp.shift 3
        base = process(base)
        rest = process(rest)
        base.last.push(*rest.last.sexp_body)
        base
      end

      def process_mlhs_paren(exp)
        _, contents = exp.shift 2

        if contents.sexp_type == :mlhs_paren
          s(:masgn, s(:array, process(contents)))
        else
          process(contents)
        end
      end

      def process_mlhs(exp)
        _, *rest = shift_all exp

        items = map_process_list(rest)
        s(:masgn, s(:array, *create_multiple_assignment_sub_types(items)))
      end

      def process_opassign(exp)
        _, lvalue, (_, operator,), value = exp.shift 4

        lvalue = process(lvalue)
        value = process(value)
        operator = operator.chop.to_sym

        create_operator_assignment_sub_type lvalue, value, operator
      end

      private

      def create_multiple_assignment_sub_types(sexp_list)
        sexp_list.map! do |item|
          create_valueless_assignment_sub_type item
        end
      end

      def create_valueless_assignment_sub_type(item)
        item = with_line_number(item.line,
                                create_regular_assignment_sub_type(item, nil))
        item.pop
        item
      end

      OPERATOR_ASSIGNMENT_MAP = {
        "||": :op_asgn_or,
        "&&": :op_asgn_and
      }.freeze

      def create_operator_assignment_sub_type(lvalue, value, operator)
        case lvalue.sexp_type
        when :aref_field
          _, arr, arglist = lvalue
          arglist.sexp_type = :arglist
          s(:op_asgn1, arr, arglist, operator, value)
        when :field
          _, obj, _, (_, field) = lvalue
          s(:op_asgn2, obj, :"#{field}=", operator, value)
        else
          value = unwrap_begin(value)
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
          _, obj, call_op, (_, field) = lvalue
          case call_op
          when :"&.", s(:op, :"&.") # Handle both 2.5 and 2.6 style ops
            s(:safe_attrasgn, obj, :"#{field}=", value)
          else
            s(:attrasgn, obj, :"#{field}=", value)
          end
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
        lvalue_type, lvalue_value = lvalue
        s(map_assignment_lvalue_type(lvalue_type), lvalue_value, value)
      end

      def map_assignment_lvalue_type(type)
        @in_method_body && ASSIGNMENT_IN_METHOD_SUB_TYPE_MAP[type] ||
          ASSIGNMENT_SUB_TYPE_MAP[type] ||
          type
      end
    end
  end
end
