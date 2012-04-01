module RipperRubyParser
  module SexpHandlers
    module Arrays
      def process_array exp
        _, elems = exp.shift 2
        s(:array, *handle_array_elements(elems))
      end

      def process_aref exp
        _, item, idx = exp.shift 3
        s(:call, process(item), :[], process(idx))
      end
    end
  end
end
