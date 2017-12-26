module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for method calls
    module MethodCalls
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

      CALL_OP_MAP = {
        '.': :call,
        '::': :call,
        '&.': :safe_call
      }.freeze

      def process_call(exp)
        _, receiver, op, ident = exp.shift 4
        type = CALL_OP_MAP.fetch op
        case ident
        when :call
          s(type, process(receiver), :call)
        else
          with_position_from_node_symbol(ident) do |method|
            s(type, process(receiver), method)
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
        type = CALL_OP_MAP.fetch op
        with_position_from_node_symbol(ident) do |method|
          args = handle_argument_list(arguments)
          s(type, process(receiver), method, *args)
        end
      end

      def process_vcall(exp)
        _, ident = exp.shift 2
        with_position_from_node_symbol(ident) do |method|
          s(:call, nil, method)
        end
      end

      def process_fcall(exp)
        _, ident = exp.shift 2
        with_position_from_node_symbol(ident) do |method|
          s(:call, nil, method)
        end
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
