# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for boolean operators" do
      it "handles :and" do
        _("foo and bar")
          .must_be_parsed_as s(:and,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar))
      end

      it "handles double :and" do
        _("foo and bar and baz")
          .must_be_parsed_as s(:and,
                               s(:call, nil, :foo),
                               s(:and,
                                 s(:call, nil, :bar),
                                 s(:call, nil, :baz)))
      end

      it "handles :or" do
        _("foo or bar")
          .must_be_parsed_as s(:or,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar))
      end

      it "handles double :or" do
        _("foo or bar or baz")
          .must_be_parsed_as s(:or,
                               s(:call, nil, :foo),
                               s(:or,
                                 s(:call, nil, :bar),
                                 s(:call, nil, :baz)))
      end

      it "handles :or after :and" do
        _("foo and bar or baz")
          .must_be_parsed_as s(:or,
                               s(:and,
                                 s(:call, nil, :foo),
                                 s(:call, nil, :bar)),
                               s(:call, nil, :baz))
      end

      it "handles :and after :or" do
        _("foo or bar and baz")
          .must_be_parsed_as s(:and,
                               s(:or,
                                 s(:call, nil, :foo),
                                 s(:call, nil, :bar)),
                               s(:call, nil, :baz))
      end

      it "converts :&& to :and" do
        _("foo && bar")
          .must_be_parsed_as s(:and,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar))
      end

      it "handles :|| after :&&" do
        _("foo && bar || baz")
          .must_be_parsed_as s(:or,
                               s(:and,
                                 s(:call, nil, :foo),
                                 s(:call, nil, :bar)),
                               s(:call, nil, :baz))
      end

      it "handles :&& after :||" do
        _("foo || bar && baz")
          .must_be_parsed_as s(:or,
                               s(:call, nil, :foo),
                               s(:and,
                                 s(:call, nil, :bar),
                                 s(:call, nil, :baz)))
      end

      it "handles :|| with parentheses" do
        _("(foo || bar) || baz")
          .must_be_parsed_as s(:or,
                               s(:or,
                                 s(:call, nil, :foo),
                                 s(:call, nil, :bar)),
                               s(:call, nil, :baz))
      end

      it "handles nested :|| with parentheses" do
        _("foo || (bar || baz) || qux")
          .must_be_parsed_as s(:or,
                               s(:call, nil, :foo),
                               s(:or,
                                 s(:or, s(:call, nil, :bar), s(:call, nil, :baz)),
                                 s(:call, nil, :qux)))
      end

      it "converts :|| to :or" do
        _("foo || bar")
          .must_be_parsed_as s(:or,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar))
      end

      it "handles triple :and" do
        _("foo and bar and baz and qux")
          .must_be_parsed_as s(:and,
                               s(:call, nil, :foo),
                               s(:and,
                                 s(:call, nil, :bar),
                                 s(:and,
                                   s(:call, nil, :baz),
                                   s(:call, nil, :qux))))
      end

      it "handles triple :&&" do
        _("foo && bar && baz && qux")
          .must_be_parsed_as s(:and,
                               s(:call, nil, :foo),
                               s(:and,
                                 s(:call, nil, :bar),
                                 s(:and,
                                   s(:call, nil, :baz),
                                   s(:call, nil, :qux))))
      end

      it "handles :!=" do
        _("foo != bar")
          .must_be_parsed_as s(:call,
                               s(:call, nil, :foo),
                               :!=,
                               s(:call, nil, :bar))
      end

      it "keeps :begin for the first argument of a binary operator" do
        _("begin; bar; end + foo")
          .must_be_parsed_as s(:call,
                               s(:begin, s(:call, nil, :bar)),
                               :+,
                               s(:call, nil, :foo))
      end

      it "keeps :begin for the second argument of a binary operator" do
        _("foo + begin; bar; end")
          .must_be_parsed_as s(:call,
                               s(:call, nil, :foo),
                               :+,
                               s(:begin, s(:call, nil, :bar)))
      end

      it "does not keep :begin for the first argument of a boolean operator" do
        _("begin; bar; end and foo")
          .must_be_parsed_as s(:and,
                               s(:call, nil, :bar),
                               s(:call, nil, :foo))
      end

      it "keeps :begin for the second argument of a boolean operator" do
        _("foo and begin; bar; end")
          .must_be_parsed_as s(:and,
                               s(:call, nil, :foo),
                               s(:begin, s(:call, nil, :bar)))
      end

      it "does not keep :begin for the first argument of a shift operator" do
        _("begin; bar; end << foo")
          .must_be_parsed_as s(:call,
                               s(:call, nil, :bar),
                               :<<,
                               s(:call, nil, :foo))
      end

      it "does not keep :begin for the second argument of a shift operator" do
        _("foo >> begin; bar; end")
          .must_be_parsed_as s(:call,
                               s(:call, nil, :foo),
                               :>>,
                               s(:call, nil, :bar))
      end
    end

    describe "for the range operator" do
      it "handles positive number literals" do
        _("1..2")
          .must_be_parsed_as s(:lit, 1..2)
      end

      it "handles negative number literals" do
        _("-1..-2")
          .must_be_parsed_as s(:lit, -1..-2)
      end

      it "handles float literals" do
        _("1.0..2.0")
          .must_be_parsed_as s(:dot2,
                               s(:lit, 1.0),
                               s(:lit, 2.0))
      end

      it "handles string literals" do
        _("'a'..'z'")
          .must_be_parsed_as s(:dot2,
                               s(:str, "a"),
                               s(:str, "z"))
      end

      it "handles non-literal begin" do
        _("foo..3")
          .must_be_parsed_as s(:dot2,
                               s(:call, nil, :foo),
                               s(:lit, 3))
      end

      it "handles non-literal end" do
        _("3..foo")
          .must_be_parsed_as s(:dot2,
                               s(:lit, 3),
                               s(:call, nil, :foo))
      end

      it "handles non-literals" do
        _("foo..bar")
          .must_be_parsed_as s(:dot2,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar))
      end
    end

    describe "for the exclusive range operator" do
      it "handles positive number literals" do
        _("1...2")
          .must_be_parsed_as s(:lit, 1...2)
      end

      it "handles negative number literals" do
        _("-1...-2")
          .must_be_parsed_as s(:lit, -1...-2)
      end

      it "handles float literals" do
        _("1.0...2.0")
          .must_be_parsed_as s(:dot3,
                               s(:lit, 1.0),
                               s(:lit, 2.0))
      end

      it "handles string literals" do
        _("'a'...'z'")
          .must_be_parsed_as s(:dot3,
                               s(:str, "a"),
                               s(:str, "z"))
      end

      it "handles non-literal begin" do
        _("foo...3")
          .must_be_parsed_as s(:dot3,
                               s(:call, nil, :foo),
                               s(:lit, 3))
      end

      it "handles non-literal end" do
        _("3...foo")
          .must_be_parsed_as s(:dot3,
                               s(:lit, 3),
                               s(:call, nil, :foo))
      end

      it "handles two non-literals" do
        _("foo...bar")
          .must_be_parsed_as s(:dot3,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar))
      end
    end

    describe "for unary operators" do
      it "handles unary minus with an integer literal" do
        _("- 1").must_be_parsed_as s(:call, s(:lit, 1), :-@)
      end

      it "handles unary minus with a float literal" do
        _("- 3.14").must_be_parsed_as s(:call, s(:lit, 3.14), :-@)
      end

      it "handles unary minus with a non-literal" do
        _("-foo")
          .must_be_parsed_as s(:call,
                               s(:call, nil, :foo),
                               :-@)
      end

      it "handles unary minus with a negative number literal" do
        _("- -1").must_be_parsed_as s(:call, s(:lit, -1), :-@)
      end

      it "handles unary plus with a number literal" do
        _("+ 1").must_be_parsed_as s(:call, s(:lit, 1), :+@)
      end

      it "handles unary plus with a non-literal" do
        _("+foo")
          .must_be_parsed_as s(:call,
                               s(:call, nil, :foo),
                               :+@)
      end

      it "handles unary !" do
        _("!foo")
          .must_be_parsed_as s(:call, s(:call, nil, :foo), :!)
      end

      it "converts :not to :!" do
        _("not foo")
          .must_be_parsed_as s(:call, s(:call, nil, :foo), :!)
      end

      it "handles unary ! with a number literal" do
        _("!1")
          .must_be_parsed_as s(:call, s(:lit, 1), :!)
      end

      it "keeps :begin for the argument" do
        _("- begin; foo; end")
          .must_be_parsed_as s(:call,
                               s(:begin, s(:call, nil, :foo)),
                               :-@)
      end
    end

    describe "for the ternary operater" do
      it "works in the simple case" do
        _("foo ? bar : baz")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:call, nil, :baz))
      end

      it "keeps :begin for the first argument" do
        _("begin; foo; end ? bar : baz")
          .must_be_parsed_as s(:if,
                               s(:begin, s(:call, nil, :foo)),
                               s(:call, nil, :bar),
                               s(:call, nil, :baz))
      end

      it "keeps :begin for the second argument" do
        _("foo ? begin; bar; end : baz")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:begin, s(:call, nil, :bar)),
                               s(:call, nil, :baz))
      end

      it "keeps :begin for the third argument" do
        _("foo ? bar : begin; baz; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:begin, s(:call, nil, :baz)))
      end
    end

    describe "for match operators" do
      it "handles :=~ with two non-literals" do
        _("foo =~ bar")
          .must_be_parsed_as s(:call,
                               s(:call, nil, :foo),
                               :=~,
                               s(:call, nil, :bar))
      end

      it "handles :=~ with literal regexp on the left hand side" do
        _("/foo/ =~ bar")
          .must_be_parsed_as s(:match2,
                               s(:lit, /foo/),
                               s(:call, nil, :bar))
      end

      it "handles :=~ with literal regexp on the right hand side" do
        _("foo =~ /bar/")
          .must_be_parsed_as s(:match3,
                               s(:lit, /bar/),
                               s(:call, nil, :foo))
      end

      it "handles negated match operators" do
        _("foo !~ bar").must_be_parsed_as s(:not,
                                            s(:call,
                                              s(:call, nil, :foo),
                                              :=~,
                                              s(:call, nil, :bar)))
      end
    end
  end
end
