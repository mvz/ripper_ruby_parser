require 'ripper_ruby_parser/sexp_handlers/helper_methods'

require 'ripper_ruby_parser/sexp_handlers/arguments'
require 'ripper_ruby_parser/sexp_handlers/assignment'
require 'ripper_ruby_parser/sexp_handlers/blocks'
require 'ripper_ruby_parser/sexp_handlers/conditionals'
require 'ripper_ruby_parser/sexp_handlers/method_calls'
require 'ripper_ruby_parser/sexp_handlers/methods'

module RipperRubyParser
  module SexpHandlers
    def self.included base
      base.class_eval do
        include HelperMethods

        include Arguments
        include Assignment
        include Blocks
        include Conditionals
        include MethodCalls
        include Methods
      end
    end
  end
end
