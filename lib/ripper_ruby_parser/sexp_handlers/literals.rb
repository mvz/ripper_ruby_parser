module RipperRubyParser
  module SexpHandlers
    module Literals
      def process_string_literal exp
        _, content = exp.shift 2

        assert_type content, :string_content
        inner = content[1]

        string = extract_inner_string inner

        s(:str, string)
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
