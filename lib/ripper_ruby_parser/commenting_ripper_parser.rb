# frozen_string_literal: true

require "ripper"
require "ripper_ruby_parser/syntax_error"
require "ripper_ruby_parser/unescape"

module RipperRubyParser
  # Variant of Ripper's SexpBuilder parser class that inserts comments as
  # Sexps into the built parse tree.
  #
  # rubocop: disable Metrics/ClassLength
  # @api private
  class CommentingRipperParser < Ripper::SexpBuilder
    def initialize(*args)
      super
      @comment = ""
      @comment_stack = []
      @delimiter_stack = []
      @space_before = false
      @seen_space = false
      @in_symbol = false
    end

    def parse
      result = super
      raise "Ripper parse failed." unless result

      Sexp.from_array(result)
    end

    private

    def on_backtick(delimiter)
      @delimiter_stack.push delimiter
      super
    end

    def on_begin(*args)
      result = super

      # Some begin blocks are not created by the 'begin' keyword. Skip
      # commenting for those kinds of blocks.
      (_, kw,), = @comment_stack.last
      if kw == "begin"
        commentize("begin", result)
      else
        result
      end
    end

    def on_void_stmt
      result = super
      result << [lineno, column]
    end

    def on_comment(tok)
      @comment += tok
    end

    def on_embdoc_beg(tok)
      @comment += tok
    end

    def on_embdoc(tok)
      @comment += tok
    end

    def on_embdoc_end(tok)
      @comment += tok
    end

    def on_kw(tok)
      super.tap do |result|
        next if @in_symbol

        case tok
        when "class", "def", "module", "BEGIN", "begin", "END"
          @comment_stack.push [result, @comment]
          @comment = ""
        when "end"
          @comment = "" if @comment_stack.any?
        end
      end
    end

    def on_module(*args)
      commentize("module", super)
    end

    def on_class(*args)
      commentize("class", super)
    end

    def on_sclass(*args)
      commentize("class", super)
    end

    def on_def(name, *args)
      (_, _, loc) = name
      commentize("def", super, loc)
    end

    def on_defs(receiver, period, name, *rest)
      (_, _, loc) = name
      commentize("def", super, loc)
    end

    def on_args_new
      [:args]
    end

    def on_args_add(list, elem)
      list << elem
    end

    def on_heredoc_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_heredoc_dedent(val, width)
      next_dedent = true
      val.map! do |e|
        if e.is_a?(Array) && e[0] == :@tstring_content
          e = dedent_element(e, width) if next_dedent
          next_dedent = e[1].end_with? "\n"
        end
        e
      end
      val
    end

    def on_heredoc_end(_delimiter)
      @delimiter_stack.pop
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

    def on_qsymbols_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_qsymbols_new
      [:qsymbols]
    end

    def on_qsymbols_add(list, elem)
      list << elem
    end

    def on_qwords_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_qwords_new
      [:qwords]
    end

    def on_qwords_add(list, elem)
      list << elem
    end

    def on_regexp_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_regexp_end(delimiter)
      @delimiter_stack.pop
      super
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

    def on_symbols_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_symbols_new
      [:symbols]
    end

    def on_symbols_add(list, elem)
      list << elem
    end

    def on_tstring_beg(delimiter)
      @delimiter_stack.push delimiter
    end

    def on_tstring_content(content)
      super << @delimiter_stack.last
    end

    def on_tstring_end(delimiter)
      @delimiter_stack.pop
      super
    end

    def on_word_new
      [:word]
    end

    def on_word_add(list, elem)
      list << elem
    end

    def on_words_beg(delimiter)
      @delimiter_stack.push delimiter
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
    end

    def on_imaginary(_token)
      @space_before = @seen_space
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

    def on_rational(_token)
      @space_before = @seen_space
      super
    end

    NUMBER_LITERAL_TYPES = [:@imaginary, :@int, :@float, :@rational].freeze

    def on_unary(operator, value)
      if !@space_before && operator == :-@ && NUMBER_LITERAL_TYPES.include?(value.first)
        type, literal, lines = value
        if literal[0] == "-"
          super
        else
          [type, "-#{literal}", lines]
        end
      else
        super
      end
    end

    def on_symbeg(delimiter)
      @delimiter_stack.push delimiter
      @in_symbol = true
    end

    def on_symbol(*args)
      @delimiter_stack.pop
      @in_symbol = false
      super
    end

    def on_embexpr_beg(_delimiter)
      @in_symbol = false
    end

    def on_dyna_symbol(*args)
      @in_symbol = false
      super
    end

    def on_ident(*args)
      @comment = ""
      super
    end

    def on_BEGIN(*args)
      commentize("BEGIN", super)
    end

    def on_END(*args)
      commentize("END", super)
    end

    def on_parse_error(message)
      super
      raise SyntaxError, message if message.start_with?("syntax error,")
    end

    def on_class_name_error(message, *)
      raise SyntaxError, message
    end

    def on_alias_error(message, *)
      raise SyntaxError, message
    end

    def on_assign_error(message, *)
      raise SyntaxError, message
    end

    def on_param_error(message, *)
      raise SyntaxError, message
    end

    def commentize(name, exp, target_loc = nil)
      raise "Non-empty comment in progress: #{@comment}" unless @comment.empty?

      if target_loc
        (_, kw, loc), comment = @comment_stack.pop until (loc <=> target_loc) == -1
      else
        (_, kw, loc), comment = @comment_stack.pop
      end

      raise "Comment stack mismatch: expected #{kw} to equal #{name}" unless kw == name

      @comment = ""
      exp.push loc
      [:comment, comment, exp]
    end
  end
  # rubocop: enable Metrics/ClassLength
end
