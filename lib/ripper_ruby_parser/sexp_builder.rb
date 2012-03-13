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

    def on_class *args
      commentize(super)
    end

    def on_def *args
      commentize(super)
    end

    def on_module *args
      commentize(super)
    end

    private

    def commentize exp
      if @comment.nil?
        exp
      else
        [:comment, @comment, exp]
      end
    end
  end
end
