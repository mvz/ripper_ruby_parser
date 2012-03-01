require 'ripper_ruby_parser/sexp_handlers/conditionals'

module RipperRubyParser
  module SexpHandlers
    def self.included base
      base.class_eval do
        include Conditionals
      end
    end
  end
end

