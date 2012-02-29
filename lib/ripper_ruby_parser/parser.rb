require 'ripper'
require 'ripper_ruby_parser/sexp_processor'

module RipperRubyParser
  class Parser
    def parse source
      Sexp.from_array Ripper.sexp source
    end
  end
end

