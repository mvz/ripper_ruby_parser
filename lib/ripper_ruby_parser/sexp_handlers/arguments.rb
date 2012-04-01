module RipperRubyParser
  module SexpHandlers
    module Arguments
      def process_args_add_block exp
        _, regular, block = exp.shift 3
        args = handle_potentially_typeless_sexp(regular)
        if block
          args << s(:block_pass, process(block))
        end
        s(:arglist, *args)
      end

      def process_args_add_star exp
        generic_add_star exp
      end

      def process_arg_paren exp
        _, args = exp.shift 2
        args = s() if args.nil?
        unless args.first.is_a? Symbol
          args.unshift :arglist
        end
        process(args)
      end

      def process_rest_param exp
        _, ident = exp.shift 2
        s(:splat, process(ident))
      end
    end
  end
end
