require 'sexp_processor'

module RipperRubyParser
  class SexpProcessor < ::SexpProcessor
    def process sexp
      unless sexp.sexp_type.is_a? Symbol
        sexp.unshift :__empty
      end

      super sexp
    end
  end
end
