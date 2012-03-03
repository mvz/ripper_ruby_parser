module RipperRubyParser
  module SexpHandlers
    module MethodCalls
      def process_method_add_arg exp
        _, method, parens = exp.shift 3
        method = process method
        s(:call, nil, method[1][1], process(parens))
      end
    end
  end
end

