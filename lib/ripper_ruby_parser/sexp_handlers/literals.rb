module RipperRubyParser
  module SexpHandlers
    module Literals
      def process_string_literal exp
        _, content = exp.shift 2
        process(content)
      end

      def process_string_content exp
        _, inner = exp.shift 2

        string = extract_inner_string(inner)
        rest = []

        if string.sexp_type == :str
          string = string[1]
        else
          rest << string
          string = ""
        end

        until exp.empty? do
          rest << process(exp.shift)
        end

        if rest.empty?
          s(:str, string)
        else
          s(:dstr, string, *rest)
        end
      end

      def process_string_embexpr exp
        _, list = exp.shift 2
        s(:evstr, process(list.first))
      end

      def process_regexp_literal exp
        _, content, _ = exp.shift 3

        string = extract_inner_string content[0]

        s(:lit, Regexp.new(string[1]))
      end

      def process_symbol_literal exp
        _, symbol = exp.shift 2
        sym = symbol[1]
        s(:lit, extract_node_symbol(sym))
      end

      def process_at_tstring_content exp
        _, string, _ = exp.shift 3
        s(:str, string)
      end

      private

      def extract_inner_string exp
        process(exp) || s(:str, "")
      end
    end
  end
end
