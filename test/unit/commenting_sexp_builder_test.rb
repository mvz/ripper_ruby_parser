require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::CommentingSexpBuilder do
  def parse_with_builder str
    builder = RipperRubyParser::CommentingSexpBuilder.new str
    builder.parse
  end

  describe "handling comments" do
    it "produces a comment node surrounding a commented def" do
      result = parse_with_builder "# Foo\ndef foo; end"
      result.must_equal [:program,
                         [[:comment,
                           "# Foo\n",
                           [:def,
                            [:@ident, "foo", [2, 4]],
                            [:params, nil, nil, nil, nil, nil],
                            [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]]
    end

    it "produces a blank comment node surrounding a def that has no comment" do
      result = parse_with_builder "def foo; end"
      result.must_equal [:program,
                         [[:comment,
                           "",
                           [:def,
                           [:@ident, "foo", [1, 4]],
                           [:params, nil, nil, nil, nil, nil],
                           [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]]
    end

    it "produces a comment node surrounding a commented class" do
      result = parse_with_builder "# Foo\nclass Foo; end"
      result.must_equal [:program,
                         [[:comment,
                           "# Foo\n",
                           [:class,
                            [:const_ref, [:@const, "Foo", [2, 6]]],
                            nil,
                            [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]]
    end

    it "produce a blank comment node surrounding a class that has no comment" do
      result = parse_with_builder "class Foo; end"
      result.must_equal [:program,
                         [[:comment,
                           "",
                           [:class,
                           [:const_ref, [:@const, "Foo", [1, 6]]],
                           nil,
                           [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]]
    end

    it "produces a comment node surrounding a commented module" do
      result = parse_with_builder "# Foo\nmodule Foo; end"
      result.must_equal [:program,
                         [[:comment,
                           "# Foo\n",
                           [:module,
                            [:const_ref, [:@const, "Foo", [2, 7]]],
                            [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]]
    end

    it "produces a blank comment node surrounding a module that has no comment" do
      result = parse_with_builder "module Foo; end"
      result.must_equal [:program,
                         [[:comment,
                           "",
                           [:module,
                           [:const_ref, [:@const, "Foo", [1, 7]]],
                           [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]]
    end

    it "is not confused by a symbol containing a keyword" do
      result = parse_with_builder ":class; def foo; end"
      result.must_equal [:program,
                         [[:symbol_literal, [:symbol, [:@kw, "class", [1, 1]]]],
                          [:comment,
                           "",
                           [:def,
                            [:@ident, "foo", [1, 12]],
                            [:params, nil, nil, nil, nil, nil],
                            [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]]
    end

    it "is not confused by a dynamic symbol" do
      result = parse_with_builder ":'foo'; def bar; end"
      result.must_equal [:program,
                         [[:dyna_symbol, [[:@tstring_content, "foo", [1, 2]]]],
                          [:comment,
                           "",
                           [:def,
                            [:@ident, "bar", [1, 12]],
                            [:params, nil, nil, nil, nil, nil],
                            [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]]
    end
  end
end

