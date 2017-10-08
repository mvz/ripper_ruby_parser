module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for array literals
    module Arrays
      def process_array(exp)
        _, elems = exp.shift 2
        return s(:array) if elems.nil?
        case elems.sexp_type
        when :words, :symbols, :args
          s(:array, *handle_array_elements(elems.sexp_body))
        else
          s(:array, *handle_array_elements(elems))
        end
      end

      def process_aref(exp)
        _, coll, idx = exp.shift 3

        coll = process(coll)
        coll = nil if coll == s(:self)

        idx = process(idx) || s(:arglist)
        idx.shift
        s(:call, coll, :[], *idx)
      end
    end
  end
end
