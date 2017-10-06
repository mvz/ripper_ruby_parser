module RipperRubyParser
  module SexpHandlers
    module Hashes
      def process_hash exp
        _, elems = exp.shift 2
        s(:hash, *process(elems))
      end

      def process_assoclist_from_args exp
        _, elems = exp.shift 2
        make_hash_items elems
      end

      # @example
      #   s(:assoc_splat, s(:vcall, s(:@ident, "bar")))
      def process_assoc_splat exp
        _, param = exp.shift 2
        s(:kwsplat, process(param))
      end

      def process_bare_assoc_hash exp
        _, elems = exp.shift 2
        s(:hash, *make_hash_items(elems))
      end

      private

      # Process list of items that can be either :assoc_new or :assoc_splat
      def make_hash_items elems
        result = s()
        elems.each do |sub_exp|
          pr = process(sub_exp)
          case pr.sexp_type
          when :assoc_new
            pr.sexp_body.each { |elem| result << elem }
          when :kwsplat
            result << pr
          else
            raise ArgumentError, pr.sexp_type
          end
        end
        result
      end
    end
  end
end
