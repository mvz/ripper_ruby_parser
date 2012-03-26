require 'ripper'
require 'ripper_ruby_parser/syntax_error'

module RipperRubyParser
  class CommentingSexpBuilder < Ripper::SexpBuilderPP
    def initialize *args
      super
      @comment = nil
      @comment_stack = []
    end

    def on_comment tok
      @comment ||= ""
      @comment += tok
      super
    end

    def on_kw tok
      case tok
      when "class", "def", "module"
        @comment_stack.push @comment
        @comment = nil
      end
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

    def on_parse_error *args
      raise SyntaxError.new(*args)
    end

    def on_class_name_error *args
      raise SyntaxError.new(*args)
    end

    private

    def commentize exp
      comment = @comment_stack.pop
      if comment.nil?
        [:comment, "", exp]
      else
        [:comment, comment, exp]
      end
    end
  end
end
