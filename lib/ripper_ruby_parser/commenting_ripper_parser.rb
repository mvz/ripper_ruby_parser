require 'ripper'
require 'ripper_ruby_parser/syntax_error'

module RipperRubyParser
  # Variant of Ripper's SexpBuilderPP parser class that inserts comments as
  # Sexps into the built parse tree.
  class CommentingRipperParser < Ripper::SexpBuilderPP
    def initialize *args
      super
      @comment = nil
      @comment_stack = []
      @in_symbol = false
    end

    def parse
      result = suppress_warnings { super }
      raise "Ripper parse failed." unless result

      Sexp.from_array(result)
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

    def on_sclass *args
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

    def on_embexpr_beg *args
      @in_symbol = false
      super
    end

    def on_dyna_symbol *args
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
      raise "Comment stack empty in #{name} event" if @comment_stack.empty?
      tok, comment = @comment_stack.pop
      @comment = nil
      unless tok == name
        raise "Expected on_#{tok} event, got on_#{name}"
      end
      [:comment, comment || "", exp]
    end

    private

    def suppress_warnings
      old_verbose = $VERBOSE
      $VERBOSE = nil
      result = yield
      $VERBOSE = old_verbose
      result
    end
  end
end
