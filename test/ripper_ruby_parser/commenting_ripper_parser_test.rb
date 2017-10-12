require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::CommentingRipperParser do
  def parse_with_builder(str)
    builder = RipperRubyParser::CommentingRipperParser.new str
    builder.parse
  end

  def empty_params_list
    @empty_params_list ||= s(:params, *([nil] * 7))
  end

  describe 'handling comments' do
    it 'produces a comment node surrounding a commented def' do
      result = parse_with_builder "# Foo\ndef foo; end"
      result.must_equal s(:program,
                          s(:stmts,
                            s(:comment,
                              "# Foo\n",
                              s(:def,
                                s(:@ident, 'foo', s(2, 4)),
                                empty_params_list,
                                s(:bodystmt, s(:stmts, s(:void_stmt)), nil, nil, nil)))))
    end

    it 'produces a blank comment node surrounding a def that has no comment' do
      result = parse_with_builder 'def foo; end'
      result.must_equal s(:program,
                          s(:stmts,
                            s(:comment,
                              '',
                              s(:def,
                                s(:@ident, 'foo', s(1, 4)),
                                empty_params_list,
                                s(:bodystmt, s(:stmts, s(:void_stmt)), nil, nil, nil)))))
    end

    it 'produces a comment node surrounding a commented class' do
      result = parse_with_builder "# Foo\nclass Foo; end"
      result.must_equal s(:program,
                          s(:stmts,
                            s(:comment,
                              "# Foo\n",
                              s(:class,
                                s(:const_ref, s(:@const, 'Foo', s(2, 6))),
                                nil,
                                s(:bodystmt, s(:stmts, s(:void_stmt)), nil, nil, nil)))))
    end

    it 'produce a blank comment node surrounding a class that has no comment' do
      result = parse_with_builder 'class Foo; end'
      result.must_equal s(:program,
                          s(:stmts,
                            s(:comment,
                              '',
                              s(:class,
                                s(:const_ref, s(:@const, 'Foo', s(1, 6))),
                                nil,
                                s(:bodystmt, s(:stmts, s(:void_stmt)), nil, nil, nil)))))
    end

    it 'produces a comment node surrounding a commented module' do
      result = parse_with_builder "# Foo\nmodule Foo; end"
      result.must_equal s(:program,
                          s(:stmts,
                            s(:comment,
                              "# Foo\n",
                              s(:module,
                                s(:const_ref, s(:@const, 'Foo', s(2, 7))),
                                s(:bodystmt, s(:stmts, s(:void_stmt)), nil, nil, nil)))))
    end

    it 'produces a blank comment node surrounding a module that has no comment' do
      result = parse_with_builder 'module Foo; end'
      result.must_equal s(:program,
                          s(:stmts,
                            s(:comment,
                              '',
                              s(:module,
                                s(:const_ref, s(:@const, 'Foo', s(1, 7))),
                                s(:bodystmt, s(:stmts, s(:void_stmt)), nil, nil, nil)))))
    end

    it 'is not confused by a symbol containing a keyword' do
      result = parse_with_builder ':class; def foo; end'
      result.must_equal s(:program,
                          s(:stmts,
                            s(:symbol_literal, s(:symbol, s(:@kw, 'class', s(1, 1)))),
                            s(:comment,
                              '',
                              s(:def,
                                s(:@ident, 'foo', s(1, 12)),
                                empty_params_list,
                                s(:bodystmt, s(:stmts, s(:void_stmt)), nil, nil, nil)))))
    end

    it 'is not confused by a dynamic symbol' do
      result = parse_with_builder ":'foo'; def bar; end"
      result.must_equal s(:program,
                          s(:stmts,
                            s(:dyna_symbol,
                              s(:xstring, s(:@tstring_content, 'foo', s(1, 2)))),
                            s(:comment,
                              '',
                              s(:def,
                                s(:@ident, 'bar', s(1, 12)),
                                empty_params_list,
                                s(:bodystmt, s(:stmts, s(:void_stmt)), nil, nil, nil)))))
    end

    it 'is not confused by a dynamic symbol containing a class definition' do
      result = parse_with_builder ":\"foo\#{class Bar;end}\""
      result.must_equal s(:program,
                          s(:stmts,
                            s(:dyna_symbol,
                              s(:xstring,
                                s(:@tstring_content, 'foo', s(1, 2)),
                                s(:string_embexpr,
                                  s(:stmts,
                                    s(:comment,
                                      '',
                                      s(:class,
                                        s(:const_ref, s(:@const, 'Bar', s(1, 13))),
                                        nil,
                                        s(:bodystmt,
                                          s(:stmts, s(:void_stmt)),
                                          nil,
                                          nil,
                                          nil)))))))))
    end
  end

  describe 'handling syntax errors' do
    it 'raises an error for an incomplete source' do
      proc {
        parse_with_builder 'def foo'
      }.must_raise RipperRubyParser::SyntaxError
    end

    it 'raises an error for an invalid class name' do
      proc {
        parse_with_builder 'class foo; end'
      }.must_raise RipperRubyParser::SyntaxError
    end

    it 'raises an error aliasing $1 as foo' do
      proc {
        parse_with_builder 'alias foo $1'
      }.must_raise RipperRubyParser::SyntaxError
    end

    it 'raises an error aliasing foo as $1' do
      proc {
        parse_with_builder 'alias $1 foo'
      }.must_raise RipperRubyParser::SyntaxError
    end

    it 'raises an error aliasing $2 as $1' do
      proc {
        parse_with_builder 'alias $1 $2'
      }.must_raise RipperRubyParser::SyntaxError
    end

    it 'raises an error assigning to $1' do
      proc {
        parse_with_builder '$1 = foo'
      }.must_raise RipperRubyParser::SyntaxError
    end

    it 'raises an error using an invalid parameter name' do
      proc {
        parse_with_builder 'def foo(BAR); end'
      }.must_raise RipperRubyParser::SyntaxError
    end
  end
end
