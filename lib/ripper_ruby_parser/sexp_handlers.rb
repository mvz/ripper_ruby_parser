require 'ripper_ruby_parser/sexp_handlers/helper_methods'

require 'ripper_ruby_parser/sexp_handlers/arguments'
require 'ripper_ruby_parser/sexp_handlers/arrays'
require 'ripper_ruby_parser/sexp_handlers/assignment'
require 'ripper_ruby_parser/sexp_handlers/blocks'
require 'ripper_ruby_parser/sexp_handlers/conditionals'
require 'ripper_ruby_parser/sexp_handlers/hashes'
require 'ripper_ruby_parser/sexp_handlers/literals'
require 'ripper_ruby_parser/sexp_handlers/loops'
require 'ripper_ruby_parser/sexp_handlers/method_calls'
require 'ripper_ruby_parser/sexp_handlers/methods'
require 'ripper_ruby_parser/sexp_handlers/operators'

module RipperRubyParser
  module SexpHandlers
    def self.included base
      base.class_eval do
        include HelperMethods

        include Arguments
        include Arrays
        include Assignment
        include Blocks
        include Conditionals
        include Hashes
        include Literals
        include Loops
        include MethodCalls
        include Methods
        include Operators
      end
    end
  end
end
