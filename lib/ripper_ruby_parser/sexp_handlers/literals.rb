# frozen_string_literal: true

module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for literals
    module Literals
      # character literals
      def process_at_CHAR(exp)
        _, val, pos = exp.shift 3
        with_position(pos, s(:str, unescape(val[1..-1])))
      end

      def process_array(exp)
        _, elems = exp.shift 2
        return s(:array) if elems.nil?

        process(elems).tap { |arr| arr.sexp_type = :array }
      end

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

      # number literals
      def process_at_int(exp)
        make_literal(exp) { |val| Integer(val) }
      end

      def process_at_float(exp)
        make_literal(exp, &:to_f)
      end

      def process_at_rational(exp)
        make_literal(exp, &:to_r)
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
