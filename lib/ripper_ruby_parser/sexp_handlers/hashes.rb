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

      def process_assoc_new exp
        _, left, right = exp.shift 3
        s(process(left), process(right))
      end

      def process_bare_assoc_hash exp
        _, elems = exp.shift 2
        s(:hash, *make_hash_items(elems))
      end

      private

      def make_hash_items elems
        result = s()
        elems.each {|sub_exp|
          process(sub_exp).each {|elm|
            result << elm
          }
        }
        result
      end
    end
  end
end

