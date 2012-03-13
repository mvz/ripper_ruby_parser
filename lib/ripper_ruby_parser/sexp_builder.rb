require 'ripper'
module RipperRubyParser
  class SexpBuilder < Ripper::SexpBuilderPP
    def initialize *args
      super
      @comment = nil
    end

    def on_comment tok
      @comment = tok
      super
    end

    def on_def *args
      result = super
      if @comment.nil?
        result
      else
        [:comment, @comment, result]
      end
    end
  end
end
