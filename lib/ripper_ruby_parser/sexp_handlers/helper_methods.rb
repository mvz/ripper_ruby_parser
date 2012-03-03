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
    end
  end
end
