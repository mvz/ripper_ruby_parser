# frozen_string_literal: true

module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for assignments
    module Assignment
      def process_assign(exp)
        _, lvalue, value = exp.shift 3
        if extra_compatible && value.sexp_type == :rescue_mod
          if [:command, :command_call].include? value[1].sexp_type
            return process s(:rescue_mod, s(:assign, lvalue, value[1]), value[2])
          end
        end

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

        left = process left
        left = left[1].sexp_body

        right = process(right)

        case right.sexp_type
        when :args
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
        process(inner).tap do |result|
          result.push process(last) if last
        end
      end

      def process_mrhs_add_star(exp)
        generic_add_star exp
      end

      def process_mlhs_add_star(exp)
        _, args, splatarg = exp.shift 3
        items = process args

        splat = process(splatarg)
        splat_item = if splat.nil?
                       s(:splat)
                     else
                       s(:splat, create_valueless_assignment_sub_type(splat))
                     end

        items[1] << splat_item
        items
      end

      def process_mlhs_add_post(exp)
        _, base, rest = exp.shift 3
        items = process(base)
        rest = process(rest)
        items[1].push(*rest[1].sexp_body)
        items
      end

      def process_mlhs_paren(exp)
        _, contents = exp.shift 2

        process(contents)
      end

      def process_mlhs(exp)
        _, *rest = shift_all exp

        items = map_process_list(rest)
        s(:masgn, s(:array, *create_multiple_assignment_sub_types(items)))
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
