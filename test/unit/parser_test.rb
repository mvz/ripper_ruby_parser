# coding: utf-8
require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  let(:parser) { RipperRubyParser::Parser.new }
  describe "#parse" do
    it "returns an s-expression" do
      result = parser.parse "foo"
      result.must_be_instance_of Sexp
    end

    it "post-processes its result with the passed sexp processor" do
      sexp_p = MiniTest::Mock.new
      sexp_p.expect :process, s(:result), [Sexp]
      sexp_p.expect :filename=, nil, ['(string)']
      sexp_p.expect :extra_compatible=, nil, [false]

      parser = RipperRubyParser::Parser.new sexp_p
      result = parser.parse "any code"

      result.must_equal s(:result)
      sexp_p.verify
    end

    describe "for an empty program" do
      it "returns nil" do
        "".must_be_parsed_as nil
      end
    end

    describe "for a class declaration" do
      it "works with a namespaced class name" do
        "class Foo::Bar; end".
          must_be_parsed_as s(:class,
                              s(:colon2, s(:const, :Foo), :Bar),
                              nil)
      end

      it "works for singleton classes" do
        "class << self; end".must_be_parsed_as s(:sclass, s(:self))
      end
    end

    describe "for a module declaration" do
      it "works with a namespaced module name" do
        "module Foo::Bar; end".
          must_be_parsed_as s(:module,
                              s(:colon2, s(:const, :Foo), :Bar))
      end
    end

    describe "for empty brackets" do
      it "works with lone ()" do
        "()".must_be_parsed_as s(:nil)
      end
    end

    describe "for the return statement" do
      it "works with no arguments" do
        "return".
          must_be_parsed_as s(:return)
      end

      it "works with one argument" do
        "return foo".
          must_be_parsed_as s(:return,
                              s(:call, nil, :foo))
      end

      it "works with a splat argument" do
        "return *foo".
          must_be_parsed_as s(:return,
                              s(:svalue,
                                s(:splat,
                                  s(:call, nil, :foo))))
      end

      it "works with multiple arguments" do
        "return foo, bar".
          must_be_parsed_as s(:return,
                              s(:array,
                                s(:call, nil, :foo),
                                s(:call, nil, :bar)))
      end

      it "works with a regular argument and a splat argument" do
        "return foo, *bar".
          must_be_parsed_as s(:return,
                              s(:array,
                                s(:call, nil, :foo),
                                s(:splat,
                                  s(:call, nil, :bar))))
      end
    end

    describe "for the until statement" do
      it "works in the prefix block case with do" do
        "until foo do; bar; end".
          must_be_parsed_as s(:until,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar), true)
      end

      it "works in the prefix block case without do" do
        "until foo; bar; end".
          must_be_parsed_as s(:until,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar), true)
      end

      it "works in the single-line postfix case" do
        "foo until bar".
          must_be_parsed_as s(:until,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo), true)
      end

      it "works in the block postfix case" do
        "begin; foo; end until bar".
          must_be_parsed_as s(:until,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo), false)
      end
    end

    describe "for the while statement" do
      it "works with do" do
        "while foo do; bar; end".
          must_be_parsed_as s(:while,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar), true)
      end

      it "works without do" do
        "while foo; bar; end".
          must_be_parsed_as s(:while,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar), true)
      end
    end

    describe "for the for statement" do
      it "works with do" do
        "for foo in bar do; baz; end".
          must_be_parsed_as s(:for,
                              s(:call, nil, :bar),
                              s(:lasgn, :foo),
                              s(:call, nil, :baz))
      end

      it "works without do" do
        "for foo in bar; baz; end".
          must_be_parsed_as s(:for,
                              s(:call, nil, :bar),
                              s(:lasgn, :foo),
                              s(:call, nil, :baz))
      end

      it "works with an empty body" do
        "for foo in bar; end".
          must_be_parsed_as s(:for,
                              s(:call, nil, :bar),
                              s(:lasgn, :foo))
      end
    end

    describe "for a begin..end block" do
      it "works with no statements" do
        "begin; end".
          must_be_parsed_as s(:nil)
      end

      it "works with one statement" do
        "begin; foo; end".
          must_be_parsed_as s(:call, nil, :foo)
      end

      it "works with multiple statements" do
        "begin; foo; bar; end".
          must_be_parsed_as s(:block,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end
    end

    describe "for the undef statement" do
      it "works with a single bareword identifier" do
        "undef foo".
          must_be_parsed_as s(:undef, s(:lit, :foo))
      end

      it "works with a single symbol" do
        "undef :foo".
          must_be_parsed_as s(:undef, s(:lit, :foo))
      end

      it "works with multiple bareword identifiers" do
        "undef foo, bar".
          must_be_parsed_as s(:block,
                              s(:undef, s(:lit, :foo)),
                              s(:undef, s(:lit, :bar)))
      end

      it "works with multiple bareword symbols" do
        "undef :foo, :bar".
          must_be_parsed_as s(:block,
                              s(:undef, s(:lit, :foo)),
                              s(:undef, s(:lit, :bar)))
      end
    end

    describe "for the alias statement" do
      it "works with regular barewords" do
        "alias foo bar".
          must_be_parsed_as s(:alias,
                              s(:lit, :foo), s(:lit, :bar))
      end

      it "works with symbols" do
        "alias :foo :bar".
          must_be_parsed_as s(:alias,
                              s(:lit, :foo), s(:lit, :bar))
      end

      it "works with operator barewords" do
        "alias + -".
          must_be_parsed_as s(:alias,
                              s(:lit, :+), s(:lit, :-))
      end

      it "works with global variables" do
        "alias $foo $bar".
          must_be_parsed_as s(:valias, :$foo, :$bar)
      end
    end

    describe "for arguments" do
      it "works for a simple case with splat" do
        "foo *bar".
          must_be_parsed_as s(:call,
                              nil,
                              :foo,
                              s(:splat, s(:call, nil, :bar)))
      end

      it "works for a multi-argument case with splat" do
        "foo bar, *baz".
          must_be_parsed_as s(:call,
                              nil,
                              :foo,
                              s(:call, nil, :bar),
                              s(:splat, s(:call, nil, :baz)))
      end

      it "works for a simple case passing a block" do
        "foo &bar".
          must_be_parsed_as s(:call, nil, :foo,
                              s(:block_pass,
                                s(:call, nil, :bar)))
      end

      it "works for a bare hash" do
        "foo bar => baz".
          must_be_parsed_as s(:call, nil, :foo,
                              s(:hash,
                                s(:call, nil, :bar),
                                s(:call, nil, :baz)))
      end
    end

    describe "for collection indexing" do
      it "works in the simple case" do
        "foo[bar]".
          must_be_parsed_as s(:call,
                              s(:call, nil, :foo),
                              :[],
                              s(:call, nil, :bar))
      end

      it "works without any indexes" do
        "foo[]".must_be_parsed_as s(:call, s(:call, nil, :foo),
                                    :[])
      end

      it "drops self from self[]" do
        "self[foo]".must_be_parsed_as s(:call, nil, :[],
                                        s(:call, nil, :foo))
      end
    end

    describe "for method definitions" do
      it "works with def with receiver" do
        "def foo.bar; end".
          must_be_parsed_as s(:defs,
                              s(:call, nil, :foo),
                              :bar,
                              s(:args))
      end

      it "works with def with receiver and multiple statements" do
        "def foo.bar; baz; qux; end".
          must_be_parsed_as s(:defs,
                              s(:call, nil, :foo),
                              :bar,
                              s(:args),
                              s(:call, nil, :baz),
                              s(:call, nil, :qux))
      end

      it "works with a method argument with a default value" do
        "def foo bar=nil; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, s(:lasgn, :bar, s(:nil))),
                              s(:nil))
      end

      it "works with several method arguments with default values" do
        "def foo bar=1, baz=2; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:lasgn, :bar, s(:lit, 1)),
                                s(:lasgn, :baz, s(:lit, 2))),
                              s(:nil))
      end

      it "works with brackets around the parameter list" do
        "def foo(bar); end".
          must_be_parsed_as s(:defn, :foo, s(:args, :bar), s(:nil))
      end

      it "works with a simple splat" do
        "def foo *bar; end".
          must_be_parsed_as s(:defn, :foo, s(:args, :"*bar"), s(:nil))
      end

      it "works with a regular argument plus splat" do
        "def foo bar, *baz; end".
          must_be_parsed_as s(:defn, :foo, s(:args, :bar, :"*baz"), s(:nil))
      end

      it "works with a nameless splat" do
        "def foo *; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :"*"),
                              s(:nil))
      end

      it "works for a simple case with explicit block parameter" do
        "def foo &bar; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :"&bar"),
                              s(:nil))
      end

      it "works with a regular argument plus explicit block parameter" do
        "def foo bar, &baz; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :bar, :"&baz"),
                              s(:nil))
      end

      it "works with a argument with default value plus explicit block parameter" do
        "def foo bar=1, &baz; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:lasgn, :bar, s(:lit, 1)),
                                :"&baz"),
                                s(:nil))
      end

      it "works with a argument with default value followed by a mandatory argument" do
        "def foo bar=1, baz; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:lasgn, :bar, s(:lit, 1)),
                                :baz),
                                s(:nil))
      end

      it "works with a splat plus explicit block parameter" do
        "def foo *bar, &baz; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :"*bar", :"&baz"),
                              s(:nil))
      end

      it "works with an argument with default value plus splat" do
        "def foo bar=1, *baz; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:lasgn, :bar, s(:lit, 1)),
                                :"*baz"),
                                s(:nil))
      end

      it "works with an argument with default value plus splat plus final mandatory arguments" do
        "def foo bar=1, *baz, qux, quuz; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:lasgn, :bar, s(:lit, 1)),
                                :"*baz", :qux, :quuz),
                                s(:nil))
      end

      it "works when the method name is an operator" do
        "def +; end".
          must_be_parsed_as s(:defn, :+, s(:args),
                              s(:nil))
      end
    end

    describe "for blocks" do
      it "works with no statements in the block body" do
        "foo do; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args))
      end

      it "works with next with no arguments" do
        "foo do; next; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args),
                              s(:next))
      end

      it "works with next with one argument" do
        "foo do; next bar; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args),
                              s(:next, s(:call, nil, :bar)))
      end

      it "works with next with several arguments" do
        "foo do; next bar, baz; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args),
                              s(:next,
                                s(:array,
                                  s(:call, nil, :bar),
                                  s(:call, nil, :baz))))
      end

      it "works with break with no arguments" do
        "foo do; break; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args),
                              s(:break))
      end

      it "works with break with one argument" do
        "foo do; break bar; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args),
                              s(:break, s(:call, nil, :bar)))
      end

      it "works with break with several arguments" do
        "foo do; break bar, baz; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args),
                              s(:break,
                                s(:array,
                                  s(:call, nil, :bar),
                                  s(:call, nil, :baz))))
      end

      it "works with redo" do
        "foo do; redo; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args),
                              s(:redo))
      end

      it "works with one argument" do
        "foo do |bar|; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar))
      end

      it "works with multiple arguments" do
        "foo do |bar, baz|; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar, :baz))
      end

      it "works with a single splat argument" do
        "foo do |*bar|; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :"*bar"))
      end

      it "works with a combination of regular arguments and a splat argument" do
        "foo do |bar, *baz|; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar, :"*baz"))
      end

    end

    describe "for yield" do
      it "works with no arguments and no brackets" do
        "yield".
          must_be_parsed_as s(:yield)
      end

      it "works with brackets but no arguments" do
        "yield()".
          must_be_parsed_as s(:yield)
      end

      it "works with one argument and no brackets" do
        "yield foo".
          must_be_parsed_as s(:yield, s(:call, nil, :foo))
      end

      it "works with one argument and brackets" do
        "yield(foo)".
          must_be_parsed_as s(:yield, s(:call, nil, :foo))
      end

      it "works with multiple arguments and no brackets" do
        "yield foo, bar".
          must_be_parsed_as s(:yield,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it "works with multiple arguments and brackets" do
        "yield(foo, bar)".
          must_be_parsed_as s(:yield,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it "works with splat" do
        "yield foo, *bar".
          must_be_parsed_as s(:yield,
                              s(:call, nil, :foo),
                              s(:splat, s(:call, nil, :bar)))
      end
    end

    describe "for the __FILE__ keyword" do
      describe "when not passing a file name" do
        it "creates a string sexp with value '(string)'" do
          "__FILE__".
            must_be_parsed_as s(:str, "(string)")
        end
      end

      describe "when passing a file name" do
        it "creates a string sexp with the file name" do
          result = parser.parse "__FILE__", "foo"
          result.must_equal s(:str, "foo")
        end
      end
    end

    describe "for the __LINE__ keyword" do
      it "creates a literal sexp with value of the line number" do
        "__LINE__".
          must_be_parsed_as s(:lit, 1)
        "\n__LINE__".
          must_be_parsed_as s(:lit, 2)
      end
    end

    describe "for the END keyword" do
      it "converts to a :postexe iterator" do
        "END { foo }".
          must_be_parsed_as s(:iter, s(:postexe), s(:args), s(:call, nil, :foo))
      end
    end

    describe "for the BEGIN keyword" do
      it "converts to a :preexe iterator" do
        "BEGIN { foo }".
          must_be_parsed_as s(:iter, s(:preexe), s(:args), s(:call, nil, :foo))
      end
    end

    describe "for constant lookups" do
      it "works when explicitely starting from the root namespace" do
        "::Foo".
          must_be_parsed_as s(:colon3, :Foo)
      end

      it "works with a three-level constant lookup" do
        "Foo::Bar::Baz".
          must_be_parsed_as s(:colon2,
                              s(:colon2, s(:const, :Foo), :Bar),
                              :Baz)
      end

      it "works looking up a constant in a non-constant" do
        "foo::Bar".must_be_parsed_as s(:colon2,
                                       s(:call, nil, :foo),
                                       :Bar)
      end
    end

    describe "for variable references" do
      it "works for self" do
        "self".
          must_be_parsed_as s(:self)
      end

      it "works for instance variables" do
        "@foo".
          must_be_parsed_as s(:ivar, :@foo)
      end

      it "works for global variables" do
        "$foo".
          must_be_parsed_as s(:gvar, :$foo)
      end

      it "works for regexp match references" do
        "$1".
          must_be_parsed_as s(:nth_ref, 1)
      end

      specify { "$'".must_be_parsed_as s(:back_ref, :"'") }
      specify { "$&".must_be_parsed_as s(:back_ref, :"&") }

      it "works for class variables" do
        "@@foo".
          must_be_parsed_as s(:cvar, :@@foo)
      end
    end

    describe "for single assignment" do
      it "works when assigning to an instance variable" do
        "@foo = bar".
          must_be_parsed_as s(:iasgn,
                              :@foo,
                              s(:call, nil, :bar))
      end

      it "works when assigning to a constant" do
        "FOO = bar".
          must_be_parsed_as s(:cdecl,
                              :FOO,
                              s(:call, nil, :bar))
      end

      it "works when assigning to a collection element" do
        "foo[bar] = baz".
          must_be_parsed_as s(:attrasgn,
                              s(:call, nil, :foo),
                              :[]=,
                              s(:call, nil, :bar),
                              s(:call, nil, :baz))
      end

      it "works when assigning to an attribute" do
        "foo.bar = baz".
          must_be_parsed_as s(:attrasgn,
                              s(:call, nil, :foo),
                              :bar=,
                              s(:call, nil, :baz))
      end

      it "works when assigning to a class variable" do
        "@@foo = bar".
          must_be_parsed_as s(:cvdecl,
                              :@@foo,
                              s(:call, nil, :bar))
      end

      it "works when assigning to a class variable inside a method" do
        "def foo; @@bar = baz; end".
          must_be_parsed_as s(:defn,
                              :foo, s(:args),
                              s(:cvasgn, :@@bar, s(:call, nil, :baz)))
      end

      it "works when assigning to a class variable inside a method with a receiver" do
        "def self.foo; @@bar = baz; end".
          must_be_parsed_as s(:defs,
                              s(:self),
                              :foo, s(:args),
                              s(:cvasgn, :@@bar, s(:call, nil, :baz)))
      end

      it "works when assigning to a global variable" do
        "$foo = bar".
          must_be_parsed_as s(:gasgn,
                              :$foo,
                              s(:call, nil, :bar))
      end
    end

    describe "for operator assignment" do
      it "works with +=" do
        "foo += bar".
          must_be_parsed_as s(:lasgn,
                              :foo,
                              s(:call,
                                s(:lvar, :foo),
                                :+,
                                s(:call, nil, :bar)))
      end

      it "works with -=" do
        "foo -= bar".
          must_be_parsed_as s(:lasgn,
                              :foo,
                              s(:call,
                                s(:lvar, :foo),
                                :-,
                                s(:call, nil, :bar)))
      end

      it "works with ||=" do
        "foo ||= bar".
          must_be_parsed_as s(:op_asgn_or,
                              s(:lvar, :foo),
                              s(:lasgn, :foo,
                                s(:call, nil, :bar)))
      end

      it "works when assigning to an instance variable" do
        "@foo += bar".
          must_be_parsed_as s(:iasgn,
                              :@foo,
                              s(:call,
                                s(:ivar, :@foo),
                                :+,
                                s(:call, nil, :bar)))
      end

      it "works when assigning to a collection element" do
        "foo[bar] += baz".
          must_be_parsed_as s(:op_asgn1,
                              s(:call, nil, :foo),
                              s(:arglist, s(:call, nil, :bar)),
                              :+,
                              s(:call, nil, :baz))
      end

      it "works with ||= when assigning to a collection element" do
        "foo[bar] ||= baz".
          must_be_parsed_as s(:op_asgn1,
                              s(:call, nil, :foo),
                              s(:arglist, s(:call, nil, :bar)),
                              :"||",
                              s(:call, nil, :baz))
      end

      it "works when assigning to an attribute" do
        "foo.bar += baz".
          must_be_parsed_as s(:op_asgn2,
                              s(:call, nil, :foo),
                              :bar=,
                              :+,
                              s(:call, nil, :baz))
      end

      it "works with ||= when assigning to an attribute" do
        "foo.bar ||= baz".
          must_be_parsed_as s(:op_asgn2,
                              s(:call, nil, :foo),
                              :bar=,
                              :"||",
                              s(:call, nil, :baz))
      end
    end

    describe "for multiple assignment" do
      it "works the same number of items on each side" do
        "foo, bar = baz, qux".
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                              s(:array,
                                s(:call, nil, :baz),
                                s(:call, nil, :qux)))
      end

      it "works with a single item on the right-hand side" do
        "foo, bar = baz".
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                              s(:to_ary,
                                s(:call, nil, :baz)))
      end

      it "works with left-hand splat" do
        "foo, *bar = baz, qux".
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:splat, s(:lasgn, :bar))),
                              s(:array,
                                s(:call, nil, :baz),
                                s(:call, nil, :qux)))
      end

      it "works with brackets around the left-hand side" do
        "(foo, bar) = baz".
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with complex destructuring" do
        "foo, (bar, baz) = qux".
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:lasgn, :foo),
                                s(:masgn,
                                  s(:array, s(:lasgn, :bar), s(:lasgn, :baz)))),
                              s(:to_ary, s(:call, nil, :qux)))
      end

      it "works with complex destructuring of the value" do
        "foo, (bar, baz) = [qux, [quz, quuz]]".
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:lasgn, :foo),
                                s(:masgn, s(:array, s(:lasgn, :bar), s(:lasgn, :baz)))),
                              s(:to_ary,
                                s(:array,
                                  s(:call, nil, :qux),
                                  s(:array, s(:call, nil, :quz), s(:call, nil, :quuz)))))
      end

      it "works with instance variables" do
        "@foo, @bar = baz".
          must_be_parsed_as s(:masgn,
                              s(:array, s(:iasgn, :@foo), s(:iasgn, :@bar)),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with class variables" do
        "@@foo, @@bar = baz".
          must_be_parsed_as s(:masgn,
                              s(:array, s(:cvdecl, :@@foo), s(:cvdecl, :@@bar)),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with attributes" do
        "foo.bar, foo.baz = qux".
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:attrasgn, s(:call, nil, :foo), :bar=),
                                s(:attrasgn, s(:call, nil, :foo), :baz=)),
                              s(:to_ary, s(:call, nil, :qux)))
      end

      it "works with collection elements" do
        "foo[1], bar[2] = baz".
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:attrasgn,
                                  s(:call, nil, :foo), :[]=, s(:lit, 1)),
                                s(:attrasgn,
                                  s(:call, nil, :bar), :[]=, s(:lit, 2))),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with constants" do
        "Foo, Bar = baz".
          must_be_parsed_as s(:masgn,
                              s(:array, s(:cdecl, :Foo), s(:cdecl, :Bar)),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with instance variables and splat" do
        "@foo, *@bar = baz".
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:iasgn, :@foo),
                                s(:splat, s(:iasgn, :@bar))),
                              s(:to_ary,
                                s(:call, nil, :baz)))
      end
    end

    describe "for operators" do
      it "handles :!=" do
        "foo != bar".
          must_be_parsed_as s(:call,
                              s(:call, nil, :foo),
                              :!=,
                              s(:call, nil, :bar))
      end

      it "handles :=~ with two non-literals" do
        "foo =~ bar".
          must_be_parsed_as s(:call,
                              s(:call, nil, :foo),
                              :=~,
                              s(:call, nil, :bar))
      end

      it "handles :=~ with literal regexp on the left hand side" do
        "/foo/ =~ bar".
          must_be_parsed_as s(:match2,
                              s(:lit, /foo/),
                              s(:call, nil, :bar))
      end

      it "handles :=~ with literal regexp on the right hand side" do
        "foo =~ /bar/".
          must_be_parsed_as s(:match3,
                              s(:lit, /bar/),
                              s(:call, nil, :foo))
      end

      it "handles unary minus with a number literal" do
        "-1".
          must_be_parsed_as s(:lit, -1)
      end

      it "handles unary minus with a non-literal" do
        "-foo".
          must_be_parsed_as s(:call,
                              s(:call, nil, :foo),
                              :-@)
      end

      it "handles unary plus with a number literal" do
        "+ 1".
          must_be_parsed_as s(:lit, 1)
      end

      it "handles unary plus with a non-literal" do
        "+ foo".
          must_be_parsed_as s(:call,
                              s(:call, nil, :foo),
                              :+@)
      end

      it "handles unary !" do
        "!foo".
          must_be_parsed_as s(:call, s(:call, nil, :foo), :!)
      end

      it "converts :not to :!" do
        "not foo".
          must_be_parsed_as s(:call, s(:call, nil, :foo), :!)
      end

      it "handles unary ! with a number literal" do
        "!1".
          must_be_parsed_as s(:call, s(:lit, 1), :!)
      end

      it "handles the range operator with positive number literals" do
        "1..2".
          must_be_parsed_as s(:lit, 1..2)
      end

      it "handles the range operator with negative number literals" do
        "-1..-2".
          must_be_parsed_as s(:lit, -1..-2)
      end

      it "handles the range operator with string literals" do
        "'a'..'z'".
          must_be_parsed_as s(:dot2,
                              s(:str, "a"),
                              s(:str, "z"))
      end

      it "handles the range operator with non-literals" do
        "foo..bar".
          must_be_parsed_as s(:dot2,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it "handles the exclusive range operator with positive number literals" do
        "1...2".
          must_be_parsed_as s(:lit, 1...2)
      end

      it "handles the exclusive range operator with negative number literals" do
        "-1...-2".
          must_be_parsed_as s(:lit, -1...-2)
      end

      it "handles the exclusive range operator with string literals" do
        "'a'...'z'".
          must_be_parsed_as s(:dot3,
                              s(:str, "a"),
                              s(:str, "z"))
      end

      it "handles the exclusive range operator with non-literals" do
        "foo...bar".
          must_be_parsed_as s(:dot3,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it "handles the ternary operator" do
        "foo ? bar : baz".
          must_be_parsed_as s(:if,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar),
                              s(:call, nil, :baz))
      end
    end

    describe "for expressions" do
      it "handles assignment inside binary operator expressions" do
        "foo + (bar = baz)".
          must_be_parsed_as s(:call,
                              s(:call, nil, :foo),
                              :+,
                              s(:lasgn,
                                :bar,
                                s(:call, nil, :baz)))
      end

      it "handles assignment inside unary operator expressions" do
        "+(foo = bar)".
          must_be_parsed_as s(:call,
                              s(:lasgn, :foo, s(:call, nil, :bar)),
                              :+@)
      end
    end

    # Note: differences in the handling of comments are not caught by Sexp's
    # implementation of equality.
    describe "for comments" do
      it "handles method comments" do
        result = parser.parse "# Foo\ndef foo; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args), s(:nil))
        result.comments.must_equal "# Foo\n"
      end

      it "handles comments for methods with explicit receiver" do
        result = parser.parse "# Foo\ndef foo.bar; end"
        result.must_equal s(:defs,
                            s(:call, nil, :foo),
                            :bar,
                            s(:args))
        result.comments.must_equal "# Foo\n"
      end

      it "matches comments to the correct entity" do
        result = parser.parse "# Foo\nclass Foo\n# Bar\ndef bar\nend\nend"
        result.must_equal s(:class, :Foo, nil,
                            s(:defn, :bar,
                              s(:args), s(:nil)))
        result.comments.must_equal "# Foo\n"
        defn = result[3]
        defn.sexp_type.must_equal :defn
        defn.comments.must_equal "# Bar\n"
      end

      it "combines multi-line comments" do
        result = parser.parse "# Foo\n# Bar\ndef foo; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args), s(:nil))
        result.comments.must_equal "# Foo\n# Bar\n"
      end

      it "drops comments inside method bodies" do
        result = parser.parse <<-END
          # Foo
          class Foo
            # foo
            def foo
              bar # this is dropped
            end

            # bar
            def bar
              baz
            end
          end
        END
        result.must_equal s(:class,
                            :Foo,
                            nil,
                            s(:defn, :foo, s(:args), s(:call, nil, :bar)),
                            s(:defn, :bar, s(:args), s(:call, nil, :baz)))
        result.comments.must_equal "# Foo\n"
        result[3].comments.must_equal "# foo\n"
        result[4].comments.must_equal "# bar\n"
      end

      it "handles the use of symbols that are keywords" do
        result = parser.parse "# Foo\ndef bar\n:class\nend"
        result.must_equal s(:defn,
                            :bar,
                            s(:args),
                            s(:lit, :class))
        result.comments.must_equal "# Foo\n"
      end

      it "handles use of singleton class inside methods" do
        result = parser.parse "# Foo\ndef bar\nclass << self\nbaz\nend\nend"
        result.must_equal s(:defn,
                            :bar,
                            s(:args),
                            s(:sclass, s(:self),
                              s(:call, nil, :baz)))
        result.comments.must_equal "# Foo\n"
      end
    end

    # Note: differences in the handling of line numbers are not caught by
    # Sexp's implementation of equality.
    describe "assigning line numbers" do
      it "works for a plain method call" do
        result = parser.parse "foo"
        result.line.must_equal 1
      end

      it "works for a method call with brackets" do
        result = parser.parse "foo()"
        result.line.must_equal 1
      end

      it "works for a method call with receiver" do
        result = parser.parse "foo.bar"
        result.line.must_equal 1
      end

      it "works for a method call with receiver and arguments" do
        result = parser.parse "foo.bar baz"
        result.line.must_equal 1
      end

      it "works for a method call with arguments" do
        result = parser.parse "foo bar"
        result.line.must_equal 1
      end

      it "works for a block with two lines" do
        result = parser.parse "foo\nbar\n"
        result.sexp_type.must_equal :block
        result[1].line.must_equal 1
        result[2].line.must_equal 2
        result.line.must_equal 1
      end

      it "works for a constant reference" do
        result = parser.parse "Foo"
        result.line.must_equal 1
      end

      it "works for an instance variable" do
        result = parser.parse "@foo"
        result.line.must_equal 1
      end

      it "works for a global variable" do
        result = parser.parse "$foo"
        result.line.must_equal 1
      end

      it "works for a class variable" do
        result = parser.parse "@@foo"
        result.line.must_equal 1
      end

      it "works for a local variable" do
        result = parser.parse "foo = bar\nfoo\n"
        result.sexp_type.must_equal :block
        result[1].line.must_equal 1
        result[2].line.must_equal 2
        result.line.must_equal 1
      end

      it "works for an integer literal" do
        result = parser.parse "42"
        result.line.must_equal 1
      end

      it "works for a float literal" do
        result = parser.parse "3.14"
        result.line.must_equal 1
      end

      it "works for a regular expression back reference" do
        result = parser.parse "$1"
        result.line.must_equal 1
      end

      it "works for self" do
        result = parser.parse "self"
        result.line.must_equal 1
      end

      it "works for __FILE__" do
        result = parser.parse "__FILE__"
        result.line.must_equal 1
      end

      it "works for nil" do
        result = parser.parse "nil"
        result.line.must_equal 1
      end

      it "works for a symbol literal" do
        result = parser.parse ":foo"
        result.line.must_equal 1
      end

      it "works for a class definition" do
        result = parser.parse "class Foo; end"
        result.line.must_equal 1
      end

      it "works for a module definition" do
        result = parser.parse "module Foo; end"
        result.line.must_equal 1
      end

      it "works for a method definition" do
        result = parser.parse "def foo; end"
        result.line.must_equal 1
      end

      it "works for assignment of the empty hash" do
        result = parser.parse "foo = {}"
        result.line.must_equal 1
      end

      it "works for multiple assignment of empty hashes" do
        result = parser.parse "foo, bar = {}, {}"
        result.line.must_equal 1
      end

      it "assigns line numbers to nested sexps that don't generate their own line numbers" do
        result = parser.parse "foo(bar) do\nnext baz\nend\n"
        result.must_equal s(:iter,
                            s(:call, nil, :foo, s(:call, nil, :bar)),
                            s(:args),
                            s(:next, s(:call, nil, :baz)))
        arglist = result[1][3]
        block = result[3]
        nums = [ arglist.line, block.line ]
        nums.must_equal [1, 2]
      end

      describe "when a line number is passed" do
        it "shifts all line numbers as appropriate" do
          result = parser.parse "foo\nbar\n", '(string)', 3
          result.must_equal s(:block,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
          result.line.must_equal 3
          result[1].line.must_equal 3
          result[2].line.must_equal 4
        end
      end
    end
  end
end
