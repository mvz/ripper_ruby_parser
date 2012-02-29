require 'sexp_processor'

module RipperRubyParser
  # Extensions to Sexp
  module SexpExt
    def fix_empty_type
      unless sexp_type.is_a? Symbol
        unshift :__empty
      end
    end
  end
end

Sexp.send :include, RipperRubyParser::SexpExt
