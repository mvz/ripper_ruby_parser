# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for regular if" do
      it "works with a single statement" do
        _("if foo; bar; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               nil)
      end

      it "works with multiple statements" do
        _("if foo; bar; baz; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:block,
                                 s(:call, nil, :bar),
                                 s(:call, nil, :baz)),
                               nil)
      end

      it "works with zero statements" do
        _("if foo; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               nil,
                               nil)
      end

      it "works with a begin..end block" do
        _("if foo; begin; bar; end; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               nil)
      end

      it "works with an else clause" do
        _("if foo; bar; else; baz; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:call, nil, :baz))
      end

      it "works with an empty main clause" do
        _("if foo; else; bar; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               nil,
                               s(:call, nil, :bar))
      end

      it "works with an empty else clause" do
        _("if foo; bar; else; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               nil)
      end

      it "handles a negative condition correctly" do
        _("if not foo; bar; end")
          .must_be_parsed_as s(:if,
                               s(:call, s(:call, nil, :foo), :!),
                               s(:call, nil, :bar),
                               nil)
      end

      it "handles bare integer literal in condition" do
        _("if 1; bar; end")
          .must_be_parsed_as s(:if,
                               s(:lit, 1),
                               s(:call, nil, :bar),
                               nil)
      end

      it "handles bare regex literal in condition" do
        _("if /foo/; bar; end")
          .must_be_parsed_as s(:if,
                               s(:match, s(:lit, /foo/)),
                               s(:call, nil, :bar),
                               nil)
      end

      it "handles interpolated regex in condition" do
        _('if /#{foo}/; bar; end')
          .must_be_parsed_as s(:if,
                               s(:dregx, "", s(:evstr, s(:call, nil, :foo))),
                               s(:call, nil, :bar),
                               nil)
      end

      it "handles block conditions" do
        _("if (foo; bar); baz; end")
          .must_be_parsed_as s(:if,
                               s(:block, s(:call, nil, :foo), s(:call, nil, :bar)),
                               s(:call, nil, :baz),
                               nil)
      end

      it "converts :dot2 to :flip2" do
        _("if foo..bar; baz; end")
          .must_be_parsed_as s(:if,
                               s(:flip2, s(:call, nil, :foo), s(:call, nil, :bar)),
                               s(:call, nil, :baz),
                               nil)
      end

      it "converts :dot3 to :flip3" do
        _("if foo...bar; baz; end")
          .must_be_parsed_as s(:if,
                               s(:flip3, s(:call, nil, :foo), s(:call, nil, :bar)),
                               s(:call, nil, :baz),
                               nil)
      end

      it "handles negative match operator" do
        _("if foo !~ bar; baz; else; qux; end")
          .must_be_parsed_as s(:if,
                               s(:call, s(:call, nil, :foo), :=~, s(:call, nil, :bar)),
                               s(:call, nil, :qux),
                               s(:call, nil, :baz))
      end

      it "cleans up begin..end block in condition" do
        _("if begin foo end; bar; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar), nil)
      end

      it "handles special conditions inside begin..end block" do
        _("if begin foo..bar end; baz; end")
          .must_be_parsed_as s(:if,
                               s(:flip2, s(:call, nil, :foo), s(:call, nil, :bar)),
                               s(:call, nil, :baz),
                               nil)
      end

      it "works with assignment in the condition" do
        _("if foo = bar; baz; end")
          .must_be_parsed_as s(:if,
                               s(:lasgn, :foo,
                                 s(:call, nil, :bar)),
                               s(:call, nil, :baz), nil)
      end

      it "works with bracketed assignment in the condition" do
        _("if (foo = bar); baz; end")
          .must_be_parsed_as s(:if,
                               s(:lasgn, :foo,
                                 s(:call, nil, :bar)),
                               s(:call, nil, :baz), nil)
      end
    end

    describe "for postfix if" do
      it "works with a simple condition" do
        _("foo if bar")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :bar),
                               s(:call, nil, :foo),
                               nil)
      end

      it "handles negative conditions" do
        _("foo if not bar")
          .must_be_parsed_as s(:if,
                               s(:call, s(:call, nil, :bar), :!),
                               s(:call, nil, :foo),
                               nil)
      end

      it "handles bare regex literal in condition" do
        _("foo if /bar/")
          .must_be_parsed_as s(:if,
                               s(:match, s(:lit, /bar/)),
                               s(:call, nil, :foo),
                               nil)
      end

      it "handles interpolated regex in condition" do
        _('foo if /#{bar}/')
          .must_be_parsed_as s(:if,
                               s(:dregx, "", s(:evstr, s(:call, nil, :bar))),
                               s(:call, nil, :foo),
                               nil)
      end

      it "handles negative match operator" do
        _("baz if foo !~ bar")
          .must_be_parsed_as s(:if,
                               s(:call, s(:call, nil, :foo), :=~, s(:call, nil, :bar)),
                               nil,
                               s(:call, nil, :baz))
      end

      it "cleans up begin..end block in condition" do
        _("foo if begin bar end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :bar),
                               s(:call, nil, :foo), nil)
      end
    end

    describe "for regular unless" do
      it "works with a single statement" do
        _("unless bar; foo; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :bar),
                               nil,
                               s(:call, nil, :foo))
      end

      it "works with multiple statements" do
        _("unless foo; bar; baz; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               nil,
                               s(:block,
                                 s(:call, nil, :bar),
                                 s(:call, nil, :baz)))
      end

      it "works with zero statements" do
        _("unless foo; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               nil,
                               nil)
      end

      it "works with an else clause" do
        _("unless foo; bar; else; baz; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :baz),
                               s(:call, nil, :bar))
      end

      it "works with an empty main clause" do
        _("unless foo; else; bar; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               nil)
      end

      it "works with an empty else block" do
        _("unless foo; bar; else; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               nil,
                               s(:call, nil, :bar))
      end

      it "handles bare regex literal in condition" do
        _("unless /foo/; bar; end")
          .must_be_parsed_as s(:if,
                               s(:match, s(:lit, /foo/)),
                               nil,
                               s(:call, nil, :bar))
      end

      it "handles interpolated regex in condition" do
        _('unless /#{foo}/; bar; end')
          .must_be_parsed_as s(:if,
                               s(:dregx, "", s(:evstr, s(:call, nil, :foo))),
                               nil,
                               s(:call, nil, :bar))
      end

      it "handles negative match operator" do
        _("unless foo !~ bar; baz; else; qux; end")
          .must_be_parsed_as s(:if,
                               s(:call, s(:call, nil, :foo), :=~, s(:call, nil, :bar)),
                               s(:call, nil, :baz),
                               s(:call, nil, :qux))
      end
    end

    describe "for postfix unless" do
      it "works with a simple condition" do
        _("foo unless bar")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :bar),
                               nil,
                               s(:call, nil, :foo))
      end

      it "handles bare regex literal in condition" do
        _("foo unless /bar/")
          .must_be_parsed_as s(:if,
                               s(:match, s(:lit, /bar/)),
                               nil,
                               s(:call, nil, :foo))
      end

      it "handles interpolated regex in condition" do
        _('foo unless /#{bar}/')
          .must_be_parsed_as s(:if,
                               s(:dregx, "", s(:evstr, s(:call, nil, :bar))),
                               nil,
                               s(:call, nil, :foo))
      end

      it "handles negative match operator" do
        _("baz unless foo !~ bar")
          .must_be_parsed_as s(:if,
                               s(:call, s(:call, nil, :foo), :=~, s(:call, nil, :bar)),
                               s(:call, nil, :baz),
                               nil)
      end
    end

    describe "for elsif" do
      it "works with a single statement" do
        _("if foo; bar; elsif baz; qux; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:if,
                                 s(:call, nil, :baz),
                                 s(:call, nil, :qux),
                                 nil))
      end

      it "works with an empty consequesnt" do
        _("if foo; bar; elsif baz; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:if,
                                 s(:call, nil, :baz),
                                 nil,
                                 nil))
      end

      it "works with an else" do
        _("if foo; bar; elsif baz; qux; else; quuz; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:if,
                                 s(:call, nil, :baz),
                                 s(:call, nil, :qux),
                                 s(:call, nil, :quuz)))
      end

      it "works with an empty else" do
        _("if foo; bar; elsif baz; qux; else; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:if,
                                 s(:call, nil, :baz),
                                 s(:call, nil, :qux),
                                 nil))
      end

      it "handles a negative condition correctly" do
        _("if foo; bar; elsif not baz; qux; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:if,
                                 s(:call, s(:call, nil, :baz), :!),
                                 s(:call, nil, :qux), nil))
      end

      it "does not replace :dot2 with :flip2" do
        _("if foo; bar; elsif baz..qux; quuz; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:if,
                                 s(:dot2, s(:call, nil, :baz), s(:call, nil, :qux)),
                                 s(:call, nil, :quuz), nil))
      end

      it "handles the negative match operator" do
        _("if foo; bar; elsif baz !~ qux; quuz; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:if,
                                 s(:not,
                                   s(:call,
                                     s(:call, nil, :baz),
                                     :=~,
                                     s(:call, nil, :qux))),
                                 s(:call, nil, :quuz),
                                 nil))
      end

      it "cleans up begin..end block in condition" do
        _("if foo; bar; elsif begin baz end; qux; end")
          .must_be_parsed_as s(:if,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:if,
                                 s(:call, nil, :baz),
                                 s(:call, nil, :qux),
                                 nil))
      end
    end

    describe "for case block" do
      it "works with a single when clause" do
        _("case foo; when bar; baz; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:when,
                                 s(:array, s(:call, nil, :bar)),
                                 s(:call, nil, :baz)),
                               nil)
      end

      it "works with multiple when clauses" do
        _("case foo; when bar; baz; when qux; quux; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:when,
                                 s(:array, s(:call, nil, :bar)),
                                 s(:call, nil, :baz)),
                               s(:when,
                                 s(:array, s(:call, nil, :qux)),
                                 s(:call, nil, :quux)),
                               nil)
      end

      it "works with multiple statements in the when block" do
        _("case foo; when bar; baz; qux; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:when,
                                 s(:array, s(:call, nil, :bar)),
                                 s(:call, nil, :baz),
                                 s(:call, nil, :qux)),
                               nil)
      end

      it "works with an else clause" do
        _("case foo; when bar; baz; else; qux; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:when,
                                 s(:array, s(:call, nil, :bar)),
                                 s(:call, nil, :baz)),
                               s(:call, nil, :qux))
      end

      it "works with multiple statements in the else block" do
        _("case foo; when bar; baz; else; qux; quuz end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:when,
                                 s(:array,
                                   s(:call, nil, :bar)),
                                 s(:call, nil, :baz)),
                               s(:block,
                                 s(:call, nil, :qux),
                                 s(:call, nil, :quuz)))
      end

      it "works with an empty when block" do
        _("case foo; when bar; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:when, s(:array, s(:call, nil, :bar)), nil),
                               nil)
      end

      it "works with an empty else block" do
        _("case foo; when bar; baz; else; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:when,
                                 s(:array, s(:call, nil, :bar)),
                                 s(:call, nil, :baz)),
                               nil)
      end

      it "works with a splat in the when clause" do
        _("case foo; when *bar; baz; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:when,
                                 s(:array,
                                   s(:splat, s(:call, nil, :bar))),
                                 s(:call, nil, :baz)),
                               nil)
      end

      it "cleans up a multi-statement begin..end in the when clause" do
        _("case foo; when bar; begin; baz; qux; end; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:when,
                                 s(:array, s(:call, nil, :bar)),
                                 s(:call, nil, :baz),
                                 s(:call, nil, :qux)),
                               nil)
      end

      it "cleans up a multi-statement begin..end at start of the when clause" do
        _("case foo; when bar; begin; baz; qux; end; quuz; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:when,
                                 s(:array, s(:call, nil, :bar)),
                                 s(:call, nil, :baz),
                                 s(:call, nil, :qux),
                                 s(:call, nil, :quuz)),
                               nil)
      end

      it "cleans up a multi-statement begin..end in the else clause" do
        _("case foo; when bar; baz; else; begin; qux; quuz; end; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:when,
                                 s(:array, s(:call, nil, :bar)),
                                 s(:call, nil, :baz)),
                               s(:block,
                                 s(:call, nil, :qux),
                                 s(:call, nil, :quuz)))
      end
    end

    describe "for a case block with in clauses" do
      it "works with a single in clause" do
        _("case foo; in bar; qux bar; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:in,
                                 s(:lasgn, :bar),
                                 s(:call, nil, :qux,
                                   s(:lvar, :bar))), nil)
      end

      it "works with a single in clause with no body" do
        _("case foo; in bar; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:in, s(:lasgn, :bar), nil),
                               nil)
      end

      it "works with a multiple in clauses" do
        _("case foo; in [\"a\"]; bar; in qux; quuz qux; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:in,
                                 s(:array_pat, nil, s(:str, "a")),
                                 s(:call, nil, :bar)),
                               s(:in,
                                 s(:lasgn, :qux),
                                 s(:call, nil, :quuz, s(:lvar, :qux))), nil)
      end

      it "works with an in clause for array matching" do
        _("case foo; in [bar, baz]; qux bar, baz; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:in,
                                 s(:array_pat, nil, s(:lvar, :bar), s(:lvar, :baz)),
                                 s(:call, nil, :qux, s(:lvar, :bar), s(:lvar, :baz))), nil)
      end

      it "works with an in clause with rest argument" do
        _("case foo; in bar, *baz; qux bar, baz; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:in,
                                 s(:array_pat, nil, s(:lvar, :bar), :"*baz"),
                                 s(:call, nil, :qux, s(:lvar, :bar), s(:lvar, :baz))), nil)
      end

      it "works with an in clause for hash matching" do
        _("case foo; in { bar: baz }; qux baz; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:in,
                                 s(:hash_pat, nil, s(:lit, :bar), s(:lvar, :baz)),
                                 s(:call, nil, :qux, s(:lvar, :baz))), nil)
      end

      it "works with an in clause for abbreviated hash matching" do
        _("case foo; in { bar: }; baz bar; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:in,
                                 s(:hash_pat, nil, s(:lit, :bar), nil),
                                 s(:call, nil, :baz, s(:lvar, :bar))), nil)
      end

      it "works with an in clause with rightward assignment" do
        _("case foo; in [String => baz]; qux baz; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:in,
                                 s(:array_pat, nil, s(:lasgn, :baz, s(:const, :String))),
                                 s(:call, nil, :qux, s(:lvar, :baz))), nil)
      end

      it "works with an in clause with caret" do
        _("case foo; in [^baz]; qux baz; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:in,
                                 s(:array_pat, nil, s(:lvar, :baz)),
                                 s(:call, nil, :qux, s(:call, nil, :baz))), nil)
      end

      it "works with an in clause with caret and parentheses" do
        skip "This Ruby version does not support caret + parens" if RUBY_VERSION < "3.1.0"
        _("case foo; in [^(baz)]; qux baz; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:in,
                                 s(:array_pat, nil, s(:call, nil, :baz)),
                                 s(:call, nil, :qux, s(:call, nil, :baz))), nil)
      end

      it "works with an in clause with carets with instance, class and global variables" do
        skip "This Ruby version does not support caret + parens" if RUBY_VERSION < "3.1.0"
        _("case foo; in [^@a, ^$b, ^@@c]; qux baz; end")
          .must_be_parsed_as s(:case,
                               s(:call, nil, :foo),
                               s(:in,
                                 s(:array_pat, nil,
                                   s(:ivar, :@a), s(:gvar, :$b), s(:cvar, :@@c)),
                                 s(:call, nil, :qux, s(:call, nil, :baz))), nil)
      end
    end

    describe "for one-line pattern matching" do
      it "works for the simple case" do
        _("1 in foo").must_be_parsed_as s(:case,
                                          s(:lit, 1),
                                          s(:in,
                                            s(:lasgn, :foo), nil), nil)
      end

      it "works for secondary assignment of matched expression" do
        _("1 in foo => bar").must_be_parsed_as s(:case,
                                                 s(:lit, 1),
                                                 s(:in,
                                                   s(:lasgn, :bar,
                                                     s(:lasgn, :foo)), nil), nil)
      end

      it "works for tertiary assignment of matched expression" do
        _("1 in foo => bar => baz").must_be_parsed_as s(:case,
                                                        s(:lit, 1),
                                                        s(:in,
                                                          s(:lasgn, :baz,
                                                            s(:lasgn, :bar,
                                                              s(:lasgn, :foo))), nil), nil)
      end
    end
  end
end
