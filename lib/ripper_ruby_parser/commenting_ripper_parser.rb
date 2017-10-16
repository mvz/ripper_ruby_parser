require 'ripper'
require 'ripper_ruby_parser/syntax_error'

module RipperRubyParser
  # Variant of Ripper's SexpBuilder parser class that inserts comments as
  # Sexps into the built parse tree.
  #
  # @api private
  class CommentingRipperParser < Ripper::SexpBuilder
    def initialize(*args)
      super
      @comment = nil
      @comment_stack = []
      @in_symbol = false
    end

    def parse
      result = suppress_warnings { super }
      raise 'Ripper parse failed.' unless result

      Sexp.from_array(result)
    end

    def on_comment(tok)
      @comment ||= ''
      @comment += tok
      super
    end

    def on_kw(tok)
      case tok
      when 'class', 'def', 'module'
        unless @in_symbol
          @comment_stack.push [tok.to_sym, @comment]
          @comment = nil
        end
      end
      super
    end

    def on_module(*args)
      commentize(:module, super)
    end

    def on_class(*args)
      commentize(:class, super)
    end

    def on_sclass(*args)
      commentize(:class, super)
    end

    def on_def(*args)
      commentize(:def, super)
    end

    def on_defs(*args)
      commentize(:def, super)
    end

    def on_args_new
      [:args]
    end

    def on_args_add(list, elem)
      list << elem
    end

    def on_mlhs_new
      [:mlhs]
    end

    def on_mlhs_add(list, elem)
      if list.first == :mlhs
        list << elem
      else
        [:mlhs_add_post, list, elem]
      end
    end

    def on_mrhs_new
      [:mrhs]
    end

    def on_mrhs_add(list, elem)
      list << elem
    end

    def on_qsymbols_new
      [:qsymbols]
    end

    def on_qsymbols_add(list, elem)
      list << elem
    end

    def on_qwords_new
      [:qwords]
    end

    def on_qwords_add(list, elem)
      list << elem
    end

    def on_regexp_new
      [:regexp]
    end

    def on_regexp_add(list, elem)
      list << elem
    end

    def on_stmts_new
      [:stmts]
    end

    def on_stmts_add(list, elem)
      list << elem
    end

    def on_string_add(list, elem)
      list << elem
    end

    def on_symbols_new
      [:symbols]
    end

    def on_symbols_add(list, elem)
      list << elem
    end

    def on_word_new
      [:word]
    end

    def on_word_add(list, elem)
      list << elem
    end

    def on_words_new
      [:words]
    end

    def on_words_add(list, elem)
      list << elem
    end

    def on_xstring_new
      [:xstring]
    end

    def on_xstring_add(list, elem)
      list << elem
    end

    def on_op(token)
      @seen_space = false
      super
    end

    def on_sp(_token)
      @seen_space = true
      super
    end

    def on_int(_token)
      @space_before = @seen_space
      super
    end

    def on_float(_token)
      @space_before = @seen_space
      super
    end

    NUMBER_LITERAL_TYPES = [:@int, :@float].freeze

    def on_unary(op, value)
      if !@space_before && op == :-@ && NUMBER_LITERAL_TYPES.include?(value.first)
        type, literal, lines = value
        if literal[0] == '-'
          super
        else
          [type, "-#{literal}", lines]
        end
      else
        super
      end
    end

    def on_symbeg(*args)
      @in_symbol = true
      super
    end

    def on_symbol(*args)
      @in_symbol = false
      super
    end

    def on_embexpr_beg(*args)
      @in_symbol = false
      super
    end

    def on_dyna_symbol(*args)
      @in_symbol = false
      super
    end

    def on_parse_error(*args)
      raise SyntaxError, *args
    end

    def on_class_name_error(*args)
      raise SyntaxError, *args
    end

    def on_alias_error(*args)
      raise SyntaxError, *args
    end

    def on_assign_error(*args)
      raise SyntaxError, *args
    end

    def on_param_error(*args)
      raise SyntaxError, *args
    end

    private

    def commentize(_name, exp)
      _tok, comment = @comment_stack.pop
      @comment = nil
      [:comment, comment || '', exp]
    end

    def suppress_warnings
      old_verbose = $VERBOSE
      $VERBOSE = nil
      result = yield
      $VERBOSE = old_verbose
      result
    end
  end
end
