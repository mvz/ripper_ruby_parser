module RipperRubyParser
  module SexpHandlers
    module Arrays
      def process_array exp
        _, elems = exp.shift 2
        elems = handle_potentially_typeless_sexp(elems)
        elems.map! do |elem|
          if elem.first.is_a? Symbol
            elem
          else
            elem.first
          end
        end
        s(:array, *elems)
      end

      def process_aref exp
        _, item, idx = exp.shift 3
        s(:call, process(item), :[], process(idx))
      end
    end
  end
end
