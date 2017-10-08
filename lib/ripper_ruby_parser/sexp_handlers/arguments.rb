module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for argument lists
    module Arguments
      def process_args_add_block(exp)
        _, regular, block = exp.shift 3
        args = process(regular)
        args << s(:block_pass, process(block)) if block
        s(:arglist, *args.sexp_body)
      end

      def process_args_add_star(exp)
        generic_add_star exp
      end

      def process_arg_paren(exp)
        _, args = exp.shift 2
        args = s() if args.nil?
        args.unshift :arglist unless args.first.is_a? Symbol
        process(args)
      end

      def process_rest_param(exp)
        _, ident = exp.shift 2
        s(:splat, process(ident))
      end
    end
  end
end
