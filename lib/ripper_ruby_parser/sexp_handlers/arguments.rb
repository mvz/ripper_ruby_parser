module RipperRubyParser
  module SexpHandlers
    module Arguments
      def process_args_add_block exp
        _, content, _ = exp.shift 3
        s(:arglist, *handle_list_with_optional_splat(content))
      end

      def process_args_add_star exp
        generic_add_star exp
      end

      def process_arg_paren exp
        _, args = exp.shift 2
        unless args.first.is_a? Symbol
          args.unshift :arglist
        end
        process(args)
      end
    end
  end
end
