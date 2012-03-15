module RipperRubyParser
  module SexpHandlers
    module HelperMethods
      def handle_list_with_optional_splat exp
        if exp.nil?
          []
        elsif exp.first.is_a? Symbol
          process(exp)
        else
          exp.map { |sub_exp| process(sub_exp) }
        end
      end

      def convert_block_args(args)
        args && s(:lasgn, args[1][1])
      end

      def handle_statement_list exp
        statements = exp.
          map { |sub_exp| process(sub_exp) }.
          reject { |sub_exp| sub_exp.sexp_type == :void_stmt }

        if statements.length == 1
          statements.first
        else
          s(:block, *statements)
        end
      end

      def identifier_node_to_symbol exp
        assert_type exp, :@ident
        _, ident, _ = exp.shift 3

        ident.to_sym
      end

      def generic_add_star exp
        _, args, splatarg = exp.shift 3
        items = args.map { |sub| process(sub) }
        items << s(:splat, process(splatarg))
        s(*items)
      end

      def is_literal? exp
        exp.sexp_type == :lit
      end

      # FIXME: Make this superfluous by ensureing sexps with type :__empty are
      # never returned by #process.
      def unwrap_empty exp
        if exp.sexp_type == :__empty
          return exp[1]
        else
          exp
        end
      end
    end
  end
end
