require 'ripper_ruby_parser/sexp_handlers/conditionals'
require 'ripper_ruby_parser/sexp_handlers/blocks'

module RipperRubyParser
  module SexpHandlers
    def self.included base
      base.class_eval do
        include Conditionals
        include Blocks
      end
    end
  end
end

