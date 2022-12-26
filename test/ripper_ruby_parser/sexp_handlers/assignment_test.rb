# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  let(:parser) { RipperRubyParser::Parser.new }

  describe "#parse" do
    describe "for single assignment" do
      it "works when assigning to a namespaced constant" do
        _("Foo::Bar = baz")
          .must_be_parsed_as s(:cdecl,
                               s(:colon2, s(:const, :Foo), :Bar),
                               s(:call, nil, :baz))
      end

      it "works when assigning to constant in the root namespace" do
        _("::Foo = bar")
          .must_be_parsed_as s(:cdecl,
                               s(:colon3, :Foo),
                               s(:call, nil, :bar))
      end

      it "works with blocks" do
        _("foo = begin; bar; end")
          .must_be_parsed_as s(:lasgn, :foo, s(:call, nil, :bar))
      end

      describe "with a right-hand splat" do
        it "works in the simple case" do
          _("foo = *bar")
            .must_be_parsed_as s(:lasgn, :foo,
                                 s(:svalue,
                                   s(:splat,
                                     s(:call, nil, :bar))))
        end

        it "works with blocks" do
          _("foo = *begin; bar; end")
            .must_be_parsed_as s(:lasgn, :foo,
                                 s(:svalue, s(:splat, s(:call, nil, :bar))))
        end
      end

      describe "with several items on the right hand side" do
        it "works in the simple case" do
          _("foo = bar, baz")
            .must_be_parsed_as s(:lasgn, :foo,
                                 s(:svalue,
                                   s(:array,
                                     s(:call, nil, :bar),
                                     s(:call, nil, :baz))))
        end

        it "works with a splat" do
          _("foo = bar, *baz")
            .must_be_parsed_as s(:lasgn, :foo,
                                 s(:svalue,
                                   s(:array,
                                     s(:call, nil, :bar),
                                     s(:splat,
                                       s(:call, nil, :baz)))))
        end
      end

      describe "with an array literal on the right hand side" do
        specify do
          _("foo = [bar, baz]")
            .must_be_parsed_as s(:lasgn, :foo,
                                 s(:array,
                                   s(:call, nil, :bar),
                                   s(:call, nil, :baz)))
        end
      end

      it "works when assigning to an instance variable" do
        _("@foo = bar")
          .must_be_parsed_as s(:iasgn,
                               :@foo,
                               s(:call, nil, :bar))
      end

      it "works when assigning to a constant" do
        _("FOO = bar")
          .must_be_parsed_as s(:cdecl,
                               :FOO,
                               s(:call, nil, :bar))
      end

      it "works when assigning to a collection element" do
        _("foo[bar] = baz")
          .must_be_parsed_as s(:attrasgn,
                               s(:call, nil, :foo),
                               :[]=,
                               s(:call, nil, :bar),
                               s(:call, nil, :baz))
      end

      it "works when assigning to an attribute" do
        _("foo.bar = baz")
          .must_be_parsed_as s(:attrasgn,
                               s(:call, nil, :foo),
                               :bar=,
                               s(:call, nil, :baz))
      end

      it "works when safe-assigning to an attribute" do
        _("foo&.bar = baz")
          .must_be_parsed_as s(:safe_attrasgn,
                               s(:call, nil, :foo),
                               :bar=,
                               s(:call, nil, :baz))
      end

      describe "when assigning to a class variable" do
        it "works outside a method" do
          _("@@foo = bar")
            .must_be_parsed_as s(:cvdecl,
                                 :@@foo,
                                 s(:call, nil, :bar))
        end

        it "works inside a method" do
          _("def foo; @@bar = baz; end")
            .must_be_parsed_as s(:defn,
                                 :foo, s(:args),
                                 s(:cvasgn, :@@bar, s(:call, nil, :baz)))
        end

        it "works inside a method with a receiver" do
          _("def self.foo; @@bar = baz; end")
            .must_be_parsed_as s(:defs,
                                 s(:self),
                                 :foo, s(:args),
                                 s(:cvasgn, :@@bar, s(:call, nil, :baz)))
        end

        it "works inside method arguments" do
          _("def foo(bar = (@@baz = qux)); end")
            .must_be_parsed_as s(:defn,
                                 :foo,
                                 s(:args,
                                   s(:lasgn, :bar,
                                     s(:cvasgn, :@@baz, s(:call, nil, :qux)))),
                                 s(:nil))
        end

        it "works inside method arguments of a singleton method" do
          _("def self.foo(bar = (@@baz = qux)); end")
            .must_be_parsed_as s(:defs,
                                 s(:self),
                                 :foo,
                                 s(:args,
                                   s(:lasgn, :bar,
                                     s(:cvasgn, :@@baz, s(:call, nil, :qux)))),
                                 s(:nil))
        end

        it "works inside the receiver in a method definition" do
          _("def (bar = (@@baz = qux)).foo; end")
            .must_be_parsed_as s(:defs,
                                 s(:lasgn, :bar,
                                   s(:cvdecl, :@@baz,
                                     s(:call, nil, :qux))), :foo,
                                 s(:args), s(:nil))
        end
      end

      it "works when assigning to a global variable" do
        _("$foo = bar")
          .must_be_parsed_as s(:gasgn,
                               :$foo,
                               s(:call, nil, :bar))
      end

      describe "with a rescue modifier" do
        it "works with assigning a bare method call" do
          _("foo = bar rescue baz")
            .must_be_parsed_as s(:lasgn, :foo,
                                 s(:rescue,
                                   s(:call, nil, :bar),
                                   s(:resbody, s(:array), s(:call, nil, :baz))))
        end

        it "works with a method call with argument" do
          _("foo = bar(baz) rescue qux")
            .must_be_parsed_as s(:lasgn, :foo,
                                 s(:rescue,
                                   s(:call, nil, :bar, s(:call, nil, :baz)),
                                   s(:resbody, s(:array), s(:call, nil, :qux))))
        end

        it "works with a method call with argument without brackets" do
          _("foo = bar baz rescue qux")
            .must_be_parsed_as s(:lasgn, :foo,
                                 s(:rescue,
                                   s(:call, nil, :bar, s(:call, nil, :baz)),
                                   s(:resbody, s(:array), s(:call, nil, :qux))))
        end

        it "works with a class method call with argument without brackets" do
          _("foo = Bar.baz qux rescue quuz")
            .must_be_parsed_as s(:lasgn, :foo,
                                 s(:rescue,
                                   s(:call, s(:const, :Bar), :baz, s(:call, nil, :qux)),
                                   s(:resbody, s(:array), s(:call, nil, :quuz))))
        end
      end

      it "sets the correct line numbers" do
        result = parser.parse "foo = {}"
        _(result.line).must_equal 1
      end
    end

    describe "for multiple assignment" do
      specify do
        _("foo, * = bar")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:lasgn, :foo), s(:splat)),
                               s(:to_ary, s(:call, nil, :bar)))
      end

      specify do
        _("(foo, *bar) = baz")
          .must_be_parsed_as s(:masgn,
                               s(:array,
                                 s(:lasgn, :foo),
                                 s(:splat, s(:lasgn, :bar))),
                               s(:to_ary, s(:call, nil, :baz)))
      end

      specify do
        _("*foo, bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:array,
                                 s(:splat, s(:lasgn, :foo)),
                                 s(:lasgn, :bar)),
                               s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with blocks" do
        _("foo, bar = begin; baz; end")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                               s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with a rescue modifier" do
        expected = s(:masgn,
                     s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                     s(:to_ary,
                       s(:rescue,
                         s(:call, nil, :baz),
                         s(:resbody, s(:array), s(:call, nil, :qux)))))

        _("foo, bar = baz rescue qux")
          .must_be_parsed_as expected
      end

      it "works the same number of items on each side" do
        _("foo, bar = baz, qux")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                               s(:array,
                                 s(:call, nil, :baz),
                                 s(:call, nil, :qux)))
      end

      it "works with a single item on the right-hand side" do
        _("foo, bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                               s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with left-hand splat" do
        _("foo, *bar = baz, qux")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:lasgn, :foo), s(:splat, s(:lasgn, :bar))),
                               s(:array,
                                 s(:call, nil, :baz),
                                 s(:call, nil, :qux)))
      end

      it "works with parentheses around the left-hand side" do
        _("(foo, bar) = baz")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                               s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with complex destructuring" do
        _("foo, (bar, baz) = qux")
          .must_be_parsed_as s(:masgn,
                               s(:array,
                                 s(:lasgn, :foo),
                                 s(:masgn,
                                   s(:array,
                                     s(:lasgn, :bar),
                                     s(:lasgn, :baz)))),
                               s(:to_ary, s(:call, nil, :qux)))
      end

      it "works with complex destructuring of the value" do
        _("foo, (bar, baz) = [qux, [quz, quuz]]")
          .must_be_parsed_as s(:masgn,
                               s(:array,
                                 s(:lasgn, :foo),
                                 s(:masgn,
                                   s(:array,
                                     s(:lasgn, :bar),
                                     s(:lasgn, :baz)))),
                               s(:to_ary,
                                 s(:array,
                                   s(:call, nil, :qux),
                                   s(:array,
                                     s(:call, nil, :quz),
                                     s(:call, nil, :quuz)))))
      end

      it "works with destructuring with multiple levels" do
        _("((foo, bar)) = baz")
          .must_be_parsed_as s(:masgn,
                               s(:array,
                                 s(:masgn,
                                   s(:array,
                                     s(:lasgn, :foo),
                                     s(:lasgn, :bar)))),
                               s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with instance variables" do
        _("@foo, @bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:iasgn, :@foo), s(:iasgn, :@bar)),
                               s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with class variables" do
        _("@@foo, @@bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:cvdecl, :@@foo), s(:cvdecl, :@@bar)),
                               s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with attributes" do
        _("foo.bar, foo.baz = qux")
          .must_be_parsed_as s(:masgn,
                               s(:array,
                                 s(:attrasgn, s(:call, nil, :foo), :bar=),
                                 s(:attrasgn, s(:call, nil, :foo), :baz=)),
                               s(:to_ary, s(:call, nil, :qux)))
      end

      it "works with collection elements" do
        _("foo[1], bar[2] = baz")
          .must_be_parsed_as s(:masgn,
                               s(:array,
                                 s(:attrasgn,
                                   s(:call, nil, :foo), :[]=, s(:lit, 1)),
                                 s(:attrasgn,
                                   s(:call, nil, :bar), :[]=, s(:lit, 2))),
                               s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with constants" do
        _("Foo, Bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:cdecl, :Foo), s(:cdecl, :Bar)),
                               s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with instance variables and splat" do
        _("@foo, *@bar = baz")
          .must_be_parsed_as s(:masgn,
                               s(:array,
                                 s(:iasgn, :@foo),
                                 s(:splat, s(:iasgn, :@bar))),
                               s(:to_ary, s(:call, nil, :baz)))
      end

      it "works with a right-hand single splat" do
        _("foo, bar = *baz")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                               s(:splat, s(:call, nil, :baz)))
      end

      it "works with a splat in a list of values on the right hand" do
        _("foo, bar = baz, *qux")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                               s(:array,
                                 s(:call, nil, :baz),
                                 s(:splat, s(:call, nil, :qux))))
      end

      it "works with a right-hand single splat with begin..end block" do
        _("foo, bar = *begin; baz; end")
          .must_be_parsed_as s(:masgn,
                               s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                               s(:splat,
                                 s(:call, nil, :baz)))
      end

      it "sets the correct line numbers" do
        result = parser.parse "foo, bar = {}, {}"
        _(result.line).must_equal 1
      end
    end

    describe "for assignment to a collection element" do
      it "handles multiple indices" do
        _("foo[bar, baz] = qux")
          .must_be_parsed_as s(:attrasgn,
                               s(:call, nil, :foo),
                               :[]=,
                               s(:call, nil, :bar),
                               s(:call, nil, :baz),
                               s(:call, nil, :qux))
      end

      it "handles safe-assigning to an attribute of the collection element" do
        _("foo[bar]&.baz = qux")
          .must_be_parsed_as s(:safe_attrasgn,
                               s(:call,
                                 s(:call, nil, :foo),
                                 :[],
                                 s(:call, nil, :bar)),
                               :baz=,
                               s(:call, nil, :qux))
      end
    end

    describe "for operator assignment" do
      it "works with +=" do
        _("foo += bar")
          .must_be_parsed_as s(:lasgn, :foo,
                               s(:call, s(:lvar, :foo),
                                 :+,
                                 s(:call, nil, :bar)))
      end

      it "works with -=" do
        _("foo -= bar")
          .must_be_parsed_as s(:lasgn, :foo,
                               s(:call, s(:lvar, :foo),
                                 :-,
                                 s(:call, nil, :bar)))
      end

      it "works with *=" do
        _("foo *= bar")
          .must_be_parsed_as s(:lasgn, :foo,
                               s(:call, s(:lvar, :foo),
                                 :*,
                                 s(:call, nil, :bar)))
      end

      it "works with /=" do
        _("foo /= bar")
          .must_be_parsed_as s(:lasgn, :foo,
                               s(:call,
                                 s(:lvar, :foo), :/,
                                 s(:call, nil, :bar)))
      end

      it "works with ||=" do
        _("foo ||= bar")
          .must_be_parsed_as s(:op_asgn_or,
                               s(:lvar, :foo),
                               s(:lasgn, :foo,
                                 s(:call, nil, :bar)))
      end

      it "works when assigning to an instance variable" do
        _("@foo += bar")
          .must_be_parsed_as s(:iasgn, :@foo,
                               s(:call,
                                 s(:ivar, :@foo), :+,
                                 s(:call, nil, :bar)))
      end

      it "works with boolean operators" do
        _("foo &&= bar")
          .must_be_parsed_as s(:op_asgn_and,
                               s(:lvar, :foo), s(:lasgn, :foo, s(:call, nil, :bar)))
      end

      it "works with boolean operators and blocks" do
        _("foo &&= begin; bar; end")
          .must_be_parsed_as s(:op_asgn_and,
                               s(:lvar, :foo), s(:lasgn, :foo, s(:call, nil, :bar)))
      end

      it "works with arithmetic operators and blocks" do
        _("foo += begin; bar; end")
          .must_be_parsed_as s(:lasgn, :foo,
                               s(:call, s(:lvar, :foo), :+, s(:call, nil, :bar)))
      end
    end

    describe "for operator assignment to an attribute" do
      it "works with +=" do
        _("foo.bar += baz")
          .must_be_parsed_as s(:op_asgn2,
                               s(:call, nil, :foo),
                               :bar=, :+,
                               s(:call, nil, :baz))
      end

      it "works with ||=" do
        _("foo.bar ||= baz")
          .must_be_parsed_as s(:op_asgn2,
                               s(:call, nil, :foo),
                               :bar=, :"||",
                               s(:call, nil, :baz))
      end

      it "works with += with a function call without parentheses" do
        _("foo.bar += baz qux")
          .must_be_parsed_as s(:op_asgn,
                               s(:call, nil, :foo),
                               s(:call, nil, :baz, s(:call, nil, :qux)),
                               :bar, :+)
      end

      it "works with += with a function call with parentheses" do
        _("foo.bar += baz(qux)")
          .must_be_parsed_as s(:op_asgn2,
                               s(:call, nil, :foo),
                               :bar=, :+,
                               s(:call, nil, :baz, s(:call, nil, :qux)))
      end

      it "works with ||= with a method call without parentheses" do
        _("foo.bar += baz.qux quuz")
          .must_be_parsed_as s(:op_asgn,
                               s(:call, nil, :foo),
                               s(:call, s(:call, nil, :baz), :qux, s(:call, nil, :quuz)),
                               :bar, :+)
      end

      it "works with ||= with a function call without parentheses" do
        _("foo.bar ||= baz qux")
          .must_be_parsed_as s(:op_asgn,
                               s(:call, nil, :foo),
                               s(:call, nil, :baz, s(:call, nil, :qux)),
                               :bar, :"||")
      end

      it "works with ||= with a function call with parentheses" do
        _("foo.bar ||= baz(qux)")
          .must_be_parsed_as s(:op_asgn2,
                               s(:call, nil, :foo),
                               :bar=, :"||",
                               s(:call, nil, :baz, s(:call, nil, :qux)))
      end

      it "works with ||= with a method call without parentheses" do
        _("foo.bar ||= baz.qux quuz")
          .must_be_parsed_as s(:op_asgn,
                               s(:call, nil, :foo),
                               s(:call, s(:call, nil, :baz), :qux, s(:call, nil, :quuz)),
                               :bar, :"||")
      end
    end

    describe "for operator assignment to a collection element" do
      it "works with +=" do
        _("foo[bar] += baz")
          .must_be_parsed_as s(:op_asgn1,
                               s(:call, nil, :foo),
                               s(:arglist, s(:call, nil, :bar)),
                               :+,
                               s(:call, nil, :baz))
      end

      it "works with ||=" do
        _("foo[bar] ||= baz")
          .must_be_parsed_as s(:op_asgn1,
                               s(:call, nil, :foo),
                               s(:arglist, s(:call, nil, :bar)),
                               :"||",
                               s(:call, nil, :baz))
      end

      it "handles multiple indices" do
        _("foo[bar, baz] += qux")
          .must_be_parsed_as s(:op_asgn1,
                               s(:call, nil, :foo),
                               s(:arglist,
                                 s(:call, nil, :bar),
                                 s(:call, nil, :baz)),
                               :+,
                               s(:call, nil, :qux))
      end

      it "works with a function call without parentheses" do
        _("foo[bar] += baz qux")
          .must_be_parsed_as s(:op_asgn1,
                               s(:call, nil, :foo),
                               s(:arglist, s(:call, nil, :bar)),
                               :+,
                               s(:call, nil, :baz, s(:call, nil, :qux)))
      end

      it "works with a function call with parentheses" do
        _("foo[bar] += baz(qux)")
          .must_be_parsed_as s(:op_asgn1,
                               s(:call, nil, :foo),
                               s(:arglist, s(:call, nil, :bar)),
                               :+,
                               s(:call, nil, :baz, s(:call, nil, :qux)))
      end

      it "works with a method call without parentheses" do
        _("foo[bar] += baz.qux quuz")
          .must_be_parsed_as s(:op_asgn1,
                               s(:call, nil, :foo),
                               s(:arglist, s(:call, nil, :bar)),
                               :+,
                               s(:call, s(:call, nil, :baz), :qux, s(:call, nil, :quuz)))
      end

      it "works with a method call with parentheses" do
        _("foo[bar] += baz.qux(quuz)")
          .must_be_parsed_as s(:op_asgn1,
                               s(:call, nil, :foo),
                               s(:arglist, s(:call, nil, :bar)),
                               :+,
                               s(:call, s(:call, nil, :baz), :qux, s(:call, nil, :quuz)))
      end
    end

    describe "for rightward assignment" do
      before do
        if RUBY_VERSION < "3.0.0"
          skip "This Ruby version does not support rightward assignment"
        end
      end

      it "works for the simple case" do
        _("42 => foo")
          .must_be_parsed_as s(:case, s(:lit, 42), s(:in, s(:lasgn, :foo), nil), nil)
      end
    end
  end
end
