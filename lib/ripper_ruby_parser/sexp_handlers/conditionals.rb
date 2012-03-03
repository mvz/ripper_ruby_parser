module RipperRubyParser
  module SexpHandlers
    module Conditionals
      def process_if exp
        _, cond, truepart, _ = exp.shift 4
        truepart = truepart.map {|stmt| process(stmt)}
        if truepart.length == 1
          truepart = truepart.first
        else
          truepart = s(:block, *truepart)
        end
        s(:if, process(cond), truepart, nil)
      end

      def process_unless_mod exp
        _, cond, truepart = exp.shift 3
        s(:if, process(cond), nil, process(truepart))
      end

      def process_unless exp
        _, cond, truepart, _ = exp.shift 4
        s(:if, process(cond), nil, handle_statement_list(truepart))
      end
    end
  end
end

