# frozen_string_literal: true

module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for method calls
    module MethodCalls
      def process_args_add_star(exp)
        generic_add_star exp
      end

      def process_args_add_block(exp)
        _, regular, block = exp.shift 3
        args = process(regular)
        args << s(:block_pass, process(block)) if block
        s(:arglist, *args.sexp_body)
      end

      def process_arg_paren(exp)
        _, args = exp.shift 2
        return s() if args.nil?

        process(args)
      end

      def process_method_add_arg(exp)
        _, call, parens = exp.shift 3
        call = process(call)
        unless parens.empty?
          parens = process(parens)
          parens.shift
        end
        parens.each do |arg|
          call << arg
        end
        call
      end

      # Handle implied hashes, such as at the end of argument lists.
      def process_bare_assoc_hash(exp)
        _, elems = exp.shift 2
        s(:hash, *make_hash_items(elems))
      end

      CALL_OP_MAP = {
        '.': :call,
        '::': :call,
        '&.': :safe_call
      }.freeze

      def process_call(exp)
        _, receiver, op, ident = exp.shift 4
        type = map_call_op op
        case ident
        when :call
          s(type, process(receiver), :call)
        else
          with_position_from_node_symbol(ident) do |method|
            s(type, unwrap_begin(process(receiver)), method)
          end
        end
      end

      def process_command(exp)
        _, ident, arglist = exp.shift 3
        with_position_from_node_symbol(ident) do |method|
          args = handle_argument_list(arglist)
          s(:call, nil, method, *args)
        end
      end

      def process_command_call(exp)
        _, receiver, op, ident, arguments = exp.shift 5
        type = map_call_op op
        with_position_from_node_symbol(ident) do |method|
          args = handle_argument_list(arguments)
          s(type, process(receiver), method, *args)
        end
      end

      def map_call_op(call_op)
        call_op = call_op.sexp_body.first.to_sym if call_op.is_a? Sexp
        CALL_OP_MAP.fetch(call_op)
      end

      def process_vcall(exp)
        _, ident = exp.shift 2
        with_position_from_node_symbol(ident) do |method|
          if method == @kwrest
            s(:lvar, method)
          else
            s(:call, nil, method)
          end
        end
      end

      def process_fcall(exp)
        _, ident = exp.shift 2
        with_position_from_node_symbol(ident) do |method|
          s(:call, nil, method)
        end
      end

      def process_aref(exp)
        _, coll, idx = exp.shift 3

        coll = process(coll)
        idx = process(idx) || s(:arglist)
        idx.shift
        s(:call, coll, :[], *idx)
      end

      def process_super(exp)
        _, args = exp.shift 2
        args = process(args)
        args.shift
        s(:super, *args)
      end
    end
  end
end
