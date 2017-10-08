module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for array literals
    module Arrays
      def process_array(exp)
        _, elems = exp.shift 2
        if elems.nil?
          s(:array)
        elsif elems.sexp_type == :words
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
