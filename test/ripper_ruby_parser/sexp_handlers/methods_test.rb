# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for instance method definitions" do
      it "treats kwrest argument as a local variable" do
        _("def foo(**bar); bar; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :"**bar"),
                               s(:lvar, :bar))
      end

      it "treats kwrest argument as a local variable when other arguments are present" do
        _("def foo(bar, **baz); baz; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :bar, :"**baz"),
                               s(:lvar, :baz))
      end

      it "treats kwrest argument as a local variable when an explicit block is present" do
        _("def foo(**bar, &baz); bar; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :"**bar", :"&baz"),
                               s(:lvar, :bar))
      end

      it "treats block kwrest argument as an lvar" do
        _("def foo(**bar); baz { |**qux| bar; qux }; end")
          .must_be_parsed_as s(:defn, :foo,
                               s(:args, :"**bar"),
                               s(:iter,
                                 s(:call, nil, :baz),
                                 s(:args, :"**qux"),
                                 s(:block,
                                   s(:lvar, :bar),
                                   s(:lvar, :qux))))
      end

      it "works with a method argument with a default value" do
        _("def foo bar=nil; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, s(:lasgn, :bar, s(:nil))),
                               s(:nil))
      end

      it "works with several method arguments with default values" do
        _("def foo bar=1, baz=2; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args,
                                 s(:lasgn, :bar, s(:lit, 1)),
                                 s(:lasgn, :baz, s(:lit, 2))),
                               s(:nil))
      end

      it "works with parentheses around the parameter list" do
        _("def foo(bar); end")
          .must_be_parsed_as s(:defn, :foo, s(:args, :bar), s(:nil))
      end

      it "works with a simple splat" do
        _("def foo *bar; end")
          .must_be_parsed_as s(:defn, :foo, s(:args, :"*bar"), s(:nil))
      end

      it "works with a regular argument plus splat" do
        _("def foo bar, *baz; end")
          .must_be_parsed_as s(:defn, :foo, s(:args, :bar, :"*baz"), s(:nil))
      end

      it "works with a nameless splat" do
        _("def foo *; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :*),
                               s(:nil))
      end

      it "works with a nameless kwrest argument" do
        _("def foo **; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :**),
                               s(:nil))
      end

      it "works for a simple case with explicit block parameter" do
        _("def foo &bar; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :"&bar"),
                               s(:nil))
      end

      it "works with a regular argument plus explicit block parameter" do
        _("def foo bar, &baz; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :bar, :"&baz"),
                               s(:nil))
      end

      it "works with a default value plus explicit block parameter" do
        _("def foo bar=1, &baz; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args,
                                 s(:lasgn, :bar, s(:lit, 1)),
                                 :"&baz"),
                               s(:nil))
      end

      it "works with a default value plus mandatory argument" do
        _("def foo bar=1, baz; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args,
                                 s(:lasgn, :bar, s(:lit, 1)),
                                 :baz),
                               s(:nil))
      end

      it "works with a splat plus explicit block parameter" do
        _("def foo *bar, &baz; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :"*bar", :"&baz"),
                               s(:nil))
      end

      it "works for a bare block parameter" do
        if RUBY_VERSION < "3.1.0"
          skip "This Ruby version does not support bare block parameters"
        end
        _("def foo &; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :&),
                               s(:nil))
      end

      it "works with a default value plus splat" do
        _("def foo bar=1, *baz; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args,
                                 s(:lasgn, :bar, s(:lit, 1)),
                                 :"*baz"),
                               s(:nil))
      end

      it "works with a default value, splat, plus final mandatory arguments" do
        _("def foo bar=1, *baz, qux, quuz; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args,
                                 s(:lasgn, :bar, s(:lit, 1)),
                                 :"*baz", :qux, :quuz),
                               s(:nil))
      end

      it "works with a named argument with a default value" do
        _("def foo bar: 1; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args,
                                 s(:kwarg, :bar, s(:lit, 1))),
                               s(:nil))
      end

      it "works with a named argument with no default value" do
        _("def foo bar:; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args,
                                 s(:kwarg, :bar)),
                               s(:nil))
      end

      it "works with a double splat" do
        _("def foo **bar; end")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :"**bar"),
                               s(:nil))
      end

      it "works with argument destructuring" do
        _("def foo((bar, baz)); end")
          .must_be_parsed_as s(:defn, :foo,
                               s(:args, s(:masgn, :bar, :baz)),
                               s(:nil))
      end

      it "works with argument destructuring including splat" do
        _("def foo((bar, *baz)); end")
          .must_be_parsed_as s(:defn, :foo,
                               s(:args, s(:masgn, :bar, :"*baz")),
                               s(:nil))
      end

      it "works with nested argument destructuring" do
        _("def foo((bar, (baz, qux))); end")
          .must_be_parsed_as s(:defn, :foo,
                               s(:args, s(:masgn, :bar, s(:masgn, :baz, :qux))),
                               s(:nil))
      end

      it "works when the method name is an operator" do
        _("def +; end")
          .must_be_parsed_as s(:defn, :+, s(:args),
                               s(:nil))
      end

      it "works when the method name is a keyword" do
        _("def for; end")
          .must_be_parsed_as s(:defn, :for, s(:args),
                               s(:nil))
      end

      it "works with argument forwarding" do
        if RUBY_VERSION < "2.7.0"
          skip "This Ruby version does not support argument forwarding"
        end
        _("def foo(...); bar(...); end")
          .must_be_parsed_as s(:defn, :foo,
                               s(:args, s(:forward_args)),
                               s(:call, nil, :bar, s(:forward_args)))
      end

      it "assigns correct line numbers when the body is empty" do
        _("def bar\nend")
          .must_be_parsed_as s(:defn,
                               :bar,
                               s(:args).line(1),
                               s(:nil).line(2)).line(1),
                             with_line_numbers: true
      end
    end

    describe "for endless instance method definitions" do
      before do
        skip "This Ruby version does not support endless methods" if RUBY_VERSION < "3.0.0"
      end

      it "works for a method with simple arguments" do
        _("def foo(bar) = baz(bar)")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :bar),
                               s(:call, nil, :baz, s(:lvar, :bar)))
      end

      it "works for a method with rescue" do
        _("def foo(bar) = baz(bar) rescue qux")
          .must_be_parsed_as s(:defn,
                               :foo,
                               s(:args, :bar),
                               s(:rescue,
                                 s(:call, nil, :baz, s(:lvar, :bar)),
                                 s(:resbody, s(:array), s(:call, nil, :qux))))
      end

      it "works for a method without arguments" do
        _("def foo = bar")
          .must_be_parsed_as s(:defn, :foo, s(:args), s(:call, nil, :bar))
      end

      it "works when the body calls a method without parentheses" do
        skip "This Ruby version does not support this syntax" if RUBY_VERSION < "3.1.0"
        _("def foo = bar 42")
          .must_be_parsed_as s(:defn, :foo, s(:args), s(:call, nil, :bar, s(:lit, 42)))
      end
    end

    describe "for singleton method definitions" do
      it "works with empty body" do
        _("def foo.bar; end")
          .must_be_parsed_as s(:defs,
                               s(:call, nil, :foo),
                               :bar,
                               s(:args),
                               s(:nil))
      end

      it "works with a body with multiple statements" do
        _("def foo.bar; baz; qux; end")
          .must_be_parsed_as s(:defs,
                               s(:call, nil, :foo),
                               :bar,
                               s(:args),
                               s(:call, nil, :baz),
                               s(:call, nil, :qux))
      end

      it "works with a simple splat" do
        _("def foo.bar *baz; end")
          .must_be_parsed_as s(:defs,
                               s(:call, nil, :foo),
                               :bar,
                               s(:args, :"*baz"),
                               s(:nil))
      end

      it "works when the method name is a keyword" do
        _("def foo.for; end")
          .must_be_parsed_as s(:defs,
                               s(:call, nil, :foo),
                               :for, s(:args),
                               s(:nil))
      end
    end

    describe "for endless singleton method definitions" do
      before do
        skip "This Ruby version does not support endless methods" if RUBY_VERSION < "3.0.0"
      end

      it "works for a method with simple arguments" do
        _("def self.foo(bar) = baz(bar)")
          .must_be_parsed_as s(:defs,
                               s(:self),
                               :foo,
                               s(:args, :bar),
                               s(:call, nil, :baz, s(:lvar, :bar)))
      end

      it "works for a method with rescue" do
        _("def self.foo(bar) = baz(bar) rescue qux")
          .must_be_parsed_as s(:defs,
                               s(:self),
                               :foo,
                               s(:args, :bar),
                               s(:rescue,
                                 s(:call, nil, :baz, s(:lvar, :bar)),
                                 s(:resbody, s(:array), s(:call, nil, :qux))))
      end

      it "works for a method without arguments" do
        _("def self.foo = bar")
          .must_be_parsed_as s(:defs, s(:self), :foo, s(:args), s(:call, nil, :bar))
      end
    end

    describe "for the alias statement" do
      it "works with regular barewords" do
        _("alias foo bar")
          .must_be_parsed_as s(:alias,
                               s(:lit, :foo), s(:lit, :bar))
      end

      it "works with symbols" do
        _("alias :foo :bar")
          .must_be_parsed_as s(:alias,
                               s(:lit, :foo), s(:lit, :bar))
      end

      it "works with operator barewords" do
        _("alias + -")
          .must_be_parsed_as s(:alias,
                               s(:lit, :+), s(:lit, :-))
      end

      it "treats keywords as symbols" do
        _("alias next foo")
          .must_be_parsed_as s(:alias, s(:lit, :next), s(:lit, :foo))
      end

      it "works with global variables" do
        _("alias $foo $bar")
          .must_be_parsed_as s(:valias, :$foo, :$bar)
      end
    end

    describe "for the undef statement" do
      it "works with a single bareword identifier" do
        _("undef foo")
          .must_be_parsed_as s(:undef, s(:lit, :foo))
      end

      it "works with a single symbol" do
        _("undef :foo")
          .must_be_parsed_as s(:undef, s(:lit, :foo))
      end

      it "works with multiple bareword identifiers" do
        _("undef foo, bar")
          .must_be_parsed_as s(:block,
                               s(:undef, s(:lit, :foo)),
                               s(:undef, s(:lit, :bar)))
      end

      it "works with multiple bareword symbols" do
        _("undef :foo, :bar")
          .must_be_parsed_as s(:block,
                               s(:undef, s(:lit, :foo)),
                               s(:undef, s(:lit, :bar)))
      end
    end

    describe "for the return statement" do
      it "works with no arguments" do
        _("return")
          .must_be_parsed_as s(:return)
      end

      it "works with one argument" do
        _("return foo")
          .must_be_parsed_as s(:return,
                               s(:call, nil, :foo))
      end

      it "works with a splat argument" do
        _("return *foo")
          .must_be_parsed_as s(:return,
                               s(:svalue,
                                 s(:splat,
                                   s(:call, nil, :foo))))
      end

      it "works with multiple arguments" do
        _("return foo, bar")
          .must_be_parsed_as s(:return,
                               s(:array,
                                 s(:call, nil, :foo),
                                 s(:call, nil, :bar)))
      end

      it "works with a regular argument and a splat argument" do
        _("return foo, *bar")
          .must_be_parsed_as s(:return,
                               s(:array,
                                 s(:call, nil, :foo),
                                 s(:splat,
                                   s(:call, nil, :bar))))
      end

      it "works with a function call with parentheses" do
        _("return foo(bar)")
          .must_be_parsed_as s(:return,
                               s(:call, nil, :foo,
                                 s(:call, nil, :bar)))
      end

      it "works with a function call without parentheses" do
        _("return foo bar")
          .must_be_parsed_as s(:return,
                               s(:call, nil, :foo,
                                 s(:call, nil, :bar)))
      end
    end

    describe "for yield" do
      it "works with no arguments and no parentheses" do
        _("yield")
          .must_be_parsed_as s(:yield)
      end

      it "works with parentheses but no arguments" do
        _("yield()")
          .must_be_parsed_as s(:yield)
      end

      it "works with one argument and no parentheses" do
        _("yield foo")
          .must_be_parsed_as s(:yield, s(:call, nil, :foo))
      end

      it "works with one argument and parentheses" do
        _("yield(foo)")
          .must_be_parsed_as s(:yield, s(:call, nil, :foo))
      end

      it "works with multiple arguments and no parentheses" do
        _("yield foo, bar")
          .must_be_parsed_as s(:yield,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar))
      end

      it "works with multiple arguments and parentheses" do
        _("yield(foo, bar)")
          .must_be_parsed_as s(:yield,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar))
      end

      it "works with splat" do
        _("yield foo, *bar")
          .must_be_parsed_as s(:yield,
                               s(:call, nil, :foo),
                               s(:splat, s(:call, nil, :bar)))
      end

      it "works with a function call with parentheses" do
        _("yield foo(bar)")
          .must_be_parsed_as s(:yield,
                               s(:call, nil, :foo,
                                 s(:call, nil, :bar)))
      end

      it "works with a function call without parentheses" do
        _("yield foo bar")
          .must_be_parsed_as s(:yield,
                               s(:call, nil, :foo,
                                 s(:call, nil, :bar)))
      end
    end
  end
end
