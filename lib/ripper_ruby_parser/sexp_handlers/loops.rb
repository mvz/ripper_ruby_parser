module RipperRubyParser
  module SexpHandlers
    module Loops
      def process_until exp
        _, cond, block = exp.shift 3
        s(:until, process(cond), handle_statement_list(block), true)
      end

      def process_while exp
        _, cond, block = exp.shift 3
        s(:while, process(cond), handle_statement_list(block), true)
      end
    end
  end
end

