require 'ripper_ruby_parser/syntax_error'

module RipperRubyParser
  module SexpHandlers
    module Errors
      def process_class_name_error exp
        raise SyntaxError.new
      end
    end
  end
end

