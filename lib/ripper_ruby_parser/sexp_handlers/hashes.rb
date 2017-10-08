module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for hash literals
    module Hashes
      # Handle hash literals sexps. These can be either empty, or contain a
      # nested :assoclist_from_args Sexp.
      #
      # @example Empty hash
      #   s(:hash, nil)
      # @example Hash with contents
      #   s(:hash, s(:assoclist_from_args, ...))
      def process_hash(exp)
        _, body = exp.shift 2
        return s(:hash) unless body
        _, elems = body
        s(:hash, *make_hash_items(elems))
      end

      # @example
      #   s(:assoc_splat, s(:vcall, s(:@ident, "bar")))
      def process_assoc_splat(exp)
        _, param = exp.shift 2
        s(:kwsplat, process(param))
      end

      # Handle implied hashes, such as at the end of argument lists.
      def process_bare_assoc_hash(exp)
        _, elems = exp.shift 2
        s(:hash, *make_hash_items(elems))
      end

      private

      # Process list of items that can be either :assoc_new or :assoc_splat
      def make_hash_items(elems)
        result = s()
        elems.each do |sub_exp|
          if sub_exp.sexp_type == :assoc_new
            sub_exp.sexp_body.each { |elem| result << process(elem) }
          else # :assoc_splat
            result << process(sub_exp)
          end
        end
        result
      end
    end
  end
end
