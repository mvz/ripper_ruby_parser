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

      private

      def handle_generic_block exp
        _, args, stmts = exp.shift 3
        s(:block, process(args), s(process(stmts.first)))
      end
    end
  end
end
