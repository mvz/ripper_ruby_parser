require 'ripper_ruby_parser/sexp_handlers/helper_methods'
require 'ripper_ruby_parser/sexp_handlers/conditionals'
require 'ripper_ruby_parser/sexp_handlers/blocks'
require 'ripper_ruby_parser/sexp_handlers/arguments'

module RipperRubyParser
  module SexpHandlers
    def self.included base
      base.class_eval do
        include HelperMethods

        include Conditionals
        include Blocks
        include Arguments
      end
    end
  end
end
