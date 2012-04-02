require 'ripper'
require 'ripper_ruby_parser/syntax_error'

module RipperRubyParser
  class CommentingSexpBuilder < Ripper::SexpBuilderPP
    def initialize *args
      super
      @comment = nil
      @comment_stack = []
      @in_symbol = false
    end

    def on_comment tok
      @comment ||= ""
      @comment += tok
      super
    end

    def on_kw tok
      case tok
      when "class", "def", "module"
        unless @in_symbol
          @comment_stack.push [tok.to_sym, @comment]
          @comment = nil
        end
      end
      super
    end

    def on_module *args
      commentize(:module, super)
    end

    def on_class *args
      commentize(:class, super)
    end

    def on_def *args
      commentize(:def, super)
    end

    def on_defs *args
      commentize(:def, super)
    end

    def on_symbeg *args
      @in_symbol = true
      super
    end

    def on_symbol *args
      @in_symbol = false
      super
    end

    def on_parse_error *args
      raise SyntaxError.new(*args)
    end

    def on_class_name_error *args
      raise SyntaxError.new(*args)
    end

    def on_alias_error *args
      raise SyntaxError.new(*args)
    end

    def on_assign_error *args
      raise SyntaxError.new(*args)
    end

    def on_param_error *args
      raise SyntaxError.new(*args)
    end

    private

    def commentize name, exp
      tok, comment = @comment_stack.pop
      unless tok == name
        p @comment_stack
        p [tok, comment]
        raise "Expected on_#{tok} event, got on_#{name}"
      end
      if comment.nil?
        [:comment, "", exp]
      else
        [:comment, comment, exp]
      end
    end
  end
end
