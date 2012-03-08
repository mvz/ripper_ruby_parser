module RipperRubyParser
  module SexpHandlers
    module Literals
      def process_string_literal exp
        _, content = exp.shift 2
        process(content)
      end

      def process_string_content exp
        _, inner, rest = exp.shift 3

        string = extract_inner_string inner

        if rest.nil?
          s(:str, string)
        else
          s(:dstr, string, process(rest))
        end
      end

      def process_string_embexpr exp
        _, list = exp.shift 2
        s(:evstr, process(list.first))
      end

      def process_regexp_literal exp
        _, content, _ = exp.shift 3

        string = extract_inner_string content[0]

        s(:lit, Regexp.new(string))
      end

      def process_symbol_literal exp
        _, symbol = exp.shift 2
        sym = symbol[1]
        s(:lit, extract_node_symbol(sym))
      end

      def extract_inner_string exp
        if exp.nil?
          ""
        else
          assert_type exp, :@tstring_content
          exp[1]
        end
      end
    end
  end
end
