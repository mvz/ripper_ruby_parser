module RipperRubyParser
  module SexpHandlers
    module Conditionals
      def process_unless_mod exp
        _, cond, truepart = exp.shift 3
        s(:if, process(cond), nil, process(truepart))
      end
    end
  end
end

