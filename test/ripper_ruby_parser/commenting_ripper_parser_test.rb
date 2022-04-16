# frozen_string_literal: true

require File.expand_path("../test_helper.rb", File.dirname(__FILE__))

describe RipperRubyParser::CommentingRipperParser do
  def parse_with_builder(str)
    builder = RipperRubyParser::CommentingRipperParser.new str
    builder.parse
  end

  def empty_params_list
    @empty_params_list ||= s(:params, *([nil] * 7))
  end

  describe "handling comments" do
    # Handle different results for dynamic symbol strings. This was changed in
    # Ruby 2.7.0, and backported to 2.6.3
    #
    # See https://bugs.ruby-lang.org/issues/15670
    let(:dsym_string_type) do
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.6.3")
        :string_content
      else
        :xstring
      end
    end

    it "produces a comment node surrounding a commented def" do
      result = parse_with_builder "# Foo\ndef foo; end"
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:comment,
                                 "# Foo\n",
                                 s(:def,
                                   s(:@ident, "foo", s(2, 4)),
                                   empty_params_list,
                                   s(:bodystmt,
                                     s(:stmts, s(:void_stmt, s(2, 12))), nil, nil, nil),
                                   s(2, 0)))))
    end

    it "produces a blank comment node surrounding a def that has no comment" do
      result = parse_with_builder "def foo; end"
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:comment,
                                 "",
                                 s(:def,
                                   s(:@ident, "foo", s(1, 4)),
                                   empty_params_list,
                                   s(:bodystmt,
                                     s(:stmts, s(:void_stmt, s(1, 12))), nil, nil, nil),
                                   s(1, 0)))))
    end

    it "produces a comment node surrounding a commented class" do
      result = parse_with_builder "# Foo\nclass Foo; end"
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:comment,
                                 "# Foo\n",
                                 s(:class,
                                   s(:const_ref, s(:@const, "Foo", s(2, 6))),
                                   nil,
                                   s(:bodystmt,
                                     s(:stmts, s(:void_stmt, s(2, 10))), nil, nil, nil),
                                   s(2, 0)))))
    end

    it "produce a blank comment node surrounding a class that has no comment" do
      result = parse_with_builder "class Foo; end"
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:comment,
                                 "",
                                 s(:class,
                                   s(:const_ref, s(:@const, "Foo", s(1, 6))),
                                   nil,
                                   s(:bodystmt,
                                     s(:stmts, s(:void_stmt, s(1, 10))), nil, nil, nil),
                                   s(1, 0)))))
    end

    it "produces a comment node surrounding a commented module" do
      result = parse_with_builder "# Foo\nmodule Foo; end"
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:comment,
                                 "# Foo\n",
                                 s(:module,
                                   s(:const_ref, s(:@const, "Foo", s(2, 7))),
                                   s(:bodystmt,
                                     s(:stmts, s(:void_stmt, s(2, 11))), nil, nil, nil),
                                   s(2, 0)))))
    end

    it "produces a blank comment node surrounding a module that has no comment" do
      result = parse_with_builder "module Foo; end"
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:comment,
                                 "",
                                 s(:module,
                                   s(:const_ref, s(:@const, "Foo", s(1, 7))),
                                   s(:bodystmt,
                                     s(:stmts, s(:void_stmt, s(1, 11))), nil, nil, nil),
                                   s(1, 0)))))
    end

    it "is not confused by a symbol containing a keyword" do
      result = parse_with_builder ":class; def foo; end"
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:symbol_literal, s(:symbol, s(:@kw, "class", s(1, 1)))),
                               s(:comment,
                                 "",
                                 s(:def,
                                   s(:@ident, "foo", s(1, 12)),
                                   empty_params_list,
                                   s(:bodystmt,
                                     s(:stmts, s(:void_stmt, s(1, 20))), nil, nil, nil),
                                   s(1, 8)))))
    end

    it "does not crash on a method named 'class'" do
      result = parse_with_builder "def class; end"
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:comment, "",
                                 s(:def,
                                   s(:@kw, "class", s(1, 4)),
                                   empty_params_list,
                                   s(:bodystmt,
                                     s(:stmts, s(:void_stmt, s(1, 14))), nil, nil, nil),
                                   s(1, 0)))))
    end

    it "is not confused by a dynamic symbol" do
      result = parse_with_builder ":'foo'; def bar; end"
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:dyna_symbol,
                                 s(dsym_string_type,
                                   s(:@tstring_content, "foo", s(1, 2), ":'"))),
                               s(:comment,
                                 "",
                                 s(:def,
                                   s(:@ident, "bar", s(1, 12)),
                                   empty_params_list,
                                   s(:bodystmt,
                                     s(:stmts, s(:void_stmt, s(1, 20))), nil, nil, nil),
                                   s(1, 8)))))
    end

    it "is not confused by a dynamic symbol containing a class definition" do
      result = parse_with_builder ":\"foo\#{class Bar;end}\""
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:dyna_symbol,
                                 s(dsym_string_type,
                                   s(:@tstring_content, "foo", s(1, 2), ':"'),
                                   s(:string_embexpr,
                                     s(:stmts,
                                       s(:comment,
                                         "",
                                         s(:class,
                                           s(:const_ref, s(:@const, "Bar", s(1, 13))),
                                           nil,
                                           s(:bodystmt,
                                             s(:stmts, s(:void_stmt, s(1, 17))),
                                             nil, nil, nil),
                                           s(1, 7)))))))))
    end

    it "turns an embedded document into a comment node" do
      result = parse_with_builder "=begin Hello\nthere\n=end\nclass Foo; end"
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:comment,
                                 "=begin Hello\nthere\n=end\n",
                                 s(:class,
                                   s(:const_ref, s(:@const, "Foo", s(4, 6))),
                                   nil,
                                   s(:bodystmt,
                                     s(:stmts, s(:void_stmt, s(4, 10))), nil, nil, nil),
                                   s(4, 0)))))
    end

    it "handles interpolation with subsequent whitespace for dedented heredocs" do
      result = parse_with_builder "<<~FOO\n  \#{bar} baz\nFOO"
      _(result).must_equal s(:program,
                             s(:stmts,
                               s(:string_literal,
                                 s(dsym_string_type,
                                   s(:@tstring_content, "", s(2, 2), "<<~FOO"),
                                   s(:string_embexpr,
                                     s(:stmts,
                                       s(:vcall, s(:@ident, "bar", s(2, 4))))),
                                   s(:@tstring_content, " baz\n", s(2, 8), "<<~FOO")))))
    end
  end

  describe "handling syntax errors" do
    it "raises an error for an incomplete source" do
      _(proc { parse_with_builder "def foo" }).must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error for an invalid class name" do
      _(proc { parse_with_builder "class foo; end" })
        .must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error aliasing $1 as foo" do
      _(proc { parse_with_builder "alias foo $1" }).must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error aliasing foo as $1" do
      _(proc { parse_with_builder "alias $1 foo" }).must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error aliasing $2 as $1" do
      _(proc { parse_with_builder "alias $1 $2" }).must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error assigning to $1" do
      _(proc { parse_with_builder "$1 = foo" }).must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error using an invalid parameter name" do
      _(proc { parse_with_builder "def foo(BAR); end" })
        .must_raise RipperRubyParser::SyntaxError
    end
  end
end
