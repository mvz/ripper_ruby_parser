module RipperRubyParser
  module SexpHandlers
    module Blocks
      def process_method_add_block exp
        _, call, block = exp.shift 3
        block = process(block)
        args = convert_block_args(block[1])
        stmt = block[2].first
        s(:iter, process(call), args, stmt)
      end

      def process_brace_block exp
        handle_generic_block exp
      end

      def process_do_block exp
        handle_generic_block exp
      end

      def process_params exp
        _, normal, defaults, rest, *_ = exp.shift 6

        args = [*normal].map do |id|
          identifier_node_to_symbol id
        end

        assigns = [*defaults].map do |pair|
          sym = identifier_node_to_symbol pair[0]
          val = process pair[1]
          s(:lasgn, sym, val)
        end

        if assigns.length > 0
          args += assigns.map {|lasgn| lasgn[1]}
          args << s(:block, *assigns)
        end

        unless rest.nil?
          name = identifier_node_to_symbol rest[1]
          args << :"*#{name}"
        end

        s(:args, *args)
      end

      private

      def handle_generic_block exp
        _, args, stmts = exp.shift 3
        s(:block, process(args), s(handle_statement_list(stmts)))
      end
    end
  end
end
