# frozen_string_literal: true

module RipperRubyParser
  module SexpHandlers
    # Sexp handers for method definitions and related constructs
    module Methods
      def process_def(exp)
        _, ident, params, body, pos = exp.shift 5

        ident, = extract_node_symbol_with_position ident

        in_method do
          params = convert_arguments(process(params))
          kwrest = kwrest_param(params)
          body = with_kwrest(kwrest) { method_body(body) }
        end

        with_position(pos, s(:defn, ident, params, *body))
      end

      def process_defs(exp)
        _, receiver, _, ident, params, body, = exp.shift 7

        ident, = extract_node_symbol_with_position ident

        in_method do
          params = convert_arguments(process(params))
          kwrest = kwrest_param(params)
          body = with_kwrest(kwrest) { method_body(body) }
        end

        s(:defs, process(receiver), ident, params, *body)
      end

      def process_return(exp)
        _, arglist = exp.shift 2
        s(:return, handle_return_argument_list(arglist))
      end

      def process_return0(exp)
        exp.shift
        s(:return)
      end

      def process_yield(exp)
        _, arglist = exp.shift 2
        s(:yield, *process(arglist).sexp_body)
      end

      def process_yield0(exp)
        exp.shift
        s(:yield)
      end

      def process_undef(exp)
        _, args = exp.shift 2

        args.map! do |sub_exp|
          s(:undef, process(sub_exp))
        end

        if args.size == 1
          args.first
        else
          s(:block, *args)
        end
      end

      def process_alias(exp)
        _, left, right = exp.shift 3

        s(:alias, process(left), process(right))
      end

      private

      def in_method
        @in_method_body = true
        result = yield
        @in_method_body = false
        result
      end

      def method_body(exp)
        block = process exp
        case block.length
        when 0
          [s(:nil).line(block.line)]
        else
          unwrap_block block
        end
      end

      SPECIAL_ARG_MARKER = {
        splat: "*",
        dsplat: "**",
        blockarg: "&"
      }.freeze

      def convert_arguments(args)
        args.line ||= args.sexp_body.first&.line
        args.sexp_body = args.sexp_body.map { |item| convert_argument item }
        args
      end

      def convert_argument(item)
        case item.sexp_type
        when :lvar
          item.last
        when *SPECIAL_ARG_MARKER.keys
          convert_marked_argument(item)
        when :masgn
          convert_masgn_argument(item)
        else
          item
        end
      end

      def convert_marked_argument(item)
        marker = SPECIAL_ARG_MARKER[item.sexp_type]
        name = extract_node_symbol item.last
        :"#{marker}#{name}"
      end

      def convert_masgn_argument(item)
        args = item[1]
        args.shift
        s(:masgn, *convert_destructuring_arguments(args))
      end

      def convert_destructuring_arguments(args)
        args.map! do |item|
          case item.sexp_type
          when :splat
            convert_marked_argument(item)
          when :masgn
            convert_masgn_argument(item)
          when :lasgn
            item[1]
          end
        end
      end

      def kwrest_param(params)
        found = params.find { |param| param.to_s =~ /^\*\*(.+)/ }
        Regexp.last_match[1].to_sym if found
      end

      def with_kwrest(kwrest)
        @kwrest.push kwrest
        result = yield
        @kwrest.pop
        result
      end

      def kwrest_arg?(method)
        @kwrest.include?(method)
      end
    end
  end
end
