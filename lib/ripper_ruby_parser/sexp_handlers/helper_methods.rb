module RipperRubyParser
  module SexpHandlers
    module HelperMethods
      def handle_list_with_optional_splat exp
        if exp.first.is_a? Symbol
          process(exp)
        else
          exp.map { |sub_exp| process(sub_exp) }
        end
      end

      def convert_block_args(args)
        args && s(:lasgn, args[1][1])
      end

      def handle_statement_list exp
        if exp.length == 1
          process(exp.first)
        else
          statements = exp.map { |sub_exp| process(sub_exp) }
          s(:block, *statements)
        end
      end

      def identifier_node_to_symbol exp
        assert_type exp, :@ident
        _, ident, _ = exp.shift 3

        ident.to_sym
      end

    end
  end
end
