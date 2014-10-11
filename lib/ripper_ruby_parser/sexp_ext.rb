require 'sexp_processor'

module RipperRubyParser
  # Extensions to Sexp
  module SexpExt
    def fix_empty_type
      unshift :__empty unless sexp_type.is_a? Symbol
    end
  end
end

Sexp.send :include, RipperRubyParser::SexpExt
