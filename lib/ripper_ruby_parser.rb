require 'ripper'
require 'ripper_ruby_parser/sexp_processor'

class RipperRubyParser
  def parse source
    Sexp.from_array Ripper.sexp source
  end
end
