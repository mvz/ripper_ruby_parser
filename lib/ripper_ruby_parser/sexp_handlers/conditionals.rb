# frozen_string_literal: true

module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for conditionals
    module Conditionals
      def process_if(exp)
        _, cond, truepart, falsepart = exp.shift 4

        construct_conditional(handle_condition(cond),
                              handle_consequent(truepart),
                              handle_consequent(falsepart))
      end

      def process_elsif(exp)
        _, cond, truepart, falsepart = exp.shift 4

        s(:if,
          unwrap_begin(process(cond)),
          handle_consequent(truepart),
          handle_consequent(falsepart))
      end

      def process_if_mod(exp)
        _, cond, truepart = exp.shift 3

        construct_conditional(handle_condition(cond),
                              process(truepart),
                              nil)
      end

      def process_unless(exp)
        _, cond, truepart, falsepart = exp.shift 4

        construct_conditional(handle_condition(cond),
                              handle_consequent(falsepart),
                              handle_consequent(truepart))
      end

      def process_unless_mod(exp)
        _, cond, truepart = exp.shift 3

        construct_conditional(handle_condition(cond),
                              nil,
                              process(truepart))
      end

      def process_case(exp)
        _, expr, clauses = exp.shift 3
        s(:case, process(expr), *process(clauses).sexp_body)
      end

      def process_when(exp)
        _, values, truepart, falsepart = exp.shift 4

        falsepart ||= s(:void_stmt)

        falsepart = unwrap_case_body process(falsepart)
        values = process(values).sexp_body
        truepart = unwrap_block process(truepart)

        s(:case_body,
          s(:when, s(:array, *values), *truepart),
          *falsepart)
      end

      def process_in(exp)
        _, pattern, truepart, falsepart = exp.shift 4

        falsepart = process(falsepart)
        falsepart = if falsepart.nil?
                      [nil]
                    else
                      falsepart.sexp_body
                    end
        pattern = process(pattern)
        adjust_rightward_assignment_pattern(pattern)

        truepart = process(truepart)
        truepart = unwrap_nil(truepart) if truepart

        s(:case_body,
          s(:in, pattern, truepart),
          *falsepart)
      end

      def process_else(exp)
        _, body = exp.shift 2
        process(body)
      end

      def process_aryptn(exp)
        _, _, body, rest, = exp.shift 5

        elements = body.map do |elem|
          if elem.sexp_type == :var_field
            create_valueless_assignment_sub_type process(elem)
          else
            unwrap_begin process(elem)
          end
        end
        if rest
          rest_var = handle_pattern(rest)
          elements << convert_marked_argument(s(:splat, rest_var))
        end
        s(:array_pat, nil, *elements)
      end

      def process_hshptn(exp)
        _, _, body, = exp.shift 4

        elements = body.flat_map do |key, value|
          if value
            [process(key), process(value)]
          else
            [handle_pattern(key), nil]
          end
        end
        s(:hash_pat, nil, *elements)
      end

      def process_fndptn(exp)
        _, wrapper, before, patterns, after = exp.shift 5

        wrapper = process(wrapper)
        before = make_splat process(before)
        after = make_splat process(after)
        patterns = patterns.map do |elem|
          if elem.sexp_type == :var_field
            create_valueless_assignment_sub_type process(elem)
          else
            unwrap_begin process(elem)
          end
        end

        s(:find_pat, wrapper, before, *patterns, after)
      end

      private

      def handle_condition(cond)
        cond = unwrap_begin process(cond)
        case cond.sexp_type
        when :lit
          return s(:match, cond) if cond.last.is_a?(Regexp)
        when :dot2
          return s(:flip2, *cond.sexp_body)
        when :dot3
          return s(:flip3, *cond.sexp_body)
        end
        cond
      end

      def handle_consequent(exp)
        unwrap_nil process(exp) if exp
      end

      def handle_pattern(exp)
        pattern = process(exp)
        case pattern.sexp_type
        when :lvar, :lit
          @local_variables << pattern[1]
        end
        pattern
      end

      def adjust_rightward_assignment_pattern(exp)
        case exp.sexp_type
        when :lvar
          exp.sexp_type = :lasgn
        when :lasgn
          adjust_rightward_assignment_pattern(exp.sexp_body.last)
        end
      end

      def construct_conditional(cond, truepart, falsepart)
        if cond.sexp_type == :not
          _, inner = cond
          s(:if, inner, falsepart, truepart)
        else
          s(:if, cond, truepart, falsepart)
        end
      end

      def unwrap_case_body(exp)
        case exp.sexp_type
        when :case_body
          exp.sexp_body
        when :void_stmt
          [nil]
        else
          [exp]
        end
      end

      def make_splat(exp)
        :"*#{exp[1]}"
      end
    end
  end
end
