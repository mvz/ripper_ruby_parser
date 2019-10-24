# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for the while statement" do
      it "works with do" do
        _("while foo do; bar; end")
          .must_be_parsed_as s(:while,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar), true)
      end

      it "works without do" do
        _("while foo; bar; end")
          .must_be_parsed_as s(:while,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar), true)
      end

      it "works in the single-line postfix case" do
        _("foo while bar")
          .must_be_parsed_as s(:while,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo), true)
      end

      it "works in the block postfix case" do
        _("begin; foo; end while bar")
          .must_be_parsed_as s(:while,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo), false)
      end

      it "handles a negative condition" do
        _("while not foo; bar; end")
          .must_be_parsed_as s(:while,
                              s(:call, s(:call, nil, :foo), :!),
                              s(:call, nil, :bar), true)
      end

      it "handles a negative condition in the postfix case" do
        _("foo while not bar")
          .must_be_parsed_as s(:while,
                              s(:call, s(:call, nil, :bar), :!),
                              s(:call, nil, :foo), true)
      end

      it "converts a negated match condition to :until" do
        _("while foo !~ bar; baz; end")
          .must_be_parsed_as s(:until,
                              s(:call, s(:call, nil, :foo), :=~, s(:call, nil, :bar)),
                              s(:call, nil, :baz), true)
      end

      it "converts a negated match condition to :until in the postfix case" do
        _("baz while foo !~ bar")
          .must_be_parsed_as s(:until,
                              s(:call, s(:call, nil, :foo), :=~, s(:call, nil, :bar)),
                              s(:call, nil, :baz), true)
      end

      it "cleans up begin..end block in condition" do
        _("while begin foo end; bar; end")
          .must_be_parsed_as s(:while,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar), true)
      end

      it "cleans up begin..end block in condition in the postfix case" do
        _("foo while begin bar end")
          .must_be_parsed_as s(:while,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo), true)
      end

      it "works with do and an empty body" do
        _("while foo do; end")
          .must_be_parsed_as s(:while,
                              s(:call, nil, :foo),
                              nil, true)
      end

      it "works without do and with an empty body" do
        _("while foo; end")
          .must_be_parsed_as s(:while,
                              s(:call, nil, :foo),
                              nil, true)
      end
    end

    describe "for the until statement" do
      it "works in the prefix block case with do" do
        _("until foo do; bar; end")
          .must_be_parsed_as s(:until,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar), true)
      end

      it "works in the prefix block case without do" do
        _("until foo; bar; end")
          .must_be_parsed_as s(:until,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar), true)
      end

      it "works in the single-line postfix case" do
        _("foo until bar")
          .must_be_parsed_as s(:until,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo), true)
      end

      it "works in the block postfix case" do
        _("begin; foo; end until bar")
          .must_be_parsed_as s(:until,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo), false)
      end

      it "handles a negative condition" do
        _("until not foo; bar; end")
          .must_be_parsed_as s(:until,
                              s(:call, s(:call, nil, :foo), :!),
                              s(:call, nil, :bar), true)
      end

      it "handles a negative condition in the postfix case" do
        _("foo until not bar")
          .must_be_parsed_as s(:until,
                              s(:call, s(:call, nil, :bar), :!),
                              s(:call, nil, :foo), true)
      end

      it "converts a negated match condition to :while" do
        _("until foo !~ bar; baz; end")
          .must_be_parsed_as s(:while,
                              s(:call, s(:call, nil, :foo), :=~, s(:call, nil, :bar)),
                              s(:call, nil, :baz), true)
      end

      it "converts a negated match condition to :while in the postfix case" do
        _("baz until foo !~ bar")
          .must_be_parsed_as s(:while,
                              s(:call, s(:call, nil, :foo), :=~, s(:call, nil, :bar)),
                              s(:call, nil, :baz), true)
      end

      it "cleans up begin..end block in condition" do
        _("until begin foo end; bar; end")
          .must_be_parsed_as s(:until,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar), true)
      end

      it "cleans up begin..end block in condition in the postfix case" do
        _("foo until begin bar end")
          .must_be_parsed_as s(:until,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo), true)
      end
    end

    describe "for the for statement" do
      it "works with do" do
        _("for foo in bar do; baz; end")
          .must_be_parsed_as s(:for,
                              s(:call, nil, :bar),
                              s(:lasgn, :foo),
                              s(:call, nil, :baz))
      end

      it "works without do" do
        _("for foo in bar; baz; end")
          .must_be_parsed_as s(:for,
                              s(:call, nil, :bar),
                              s(:lasgn, :foo),
                              s(:call, nil, :baz))
      end

      it "works with an empty body" do
        _("for foo in bar; end")
          .must_be_parsed_as s(:for,
                              s(:call, nil, :bar),
                              s(:lasgn, :foo))
      end

      it "works with explicit multiple assignment" do
        _("for foo, bar in baz; end")
          .must_be_parsed_as s(:for,
                              s(:call, nil, :baz),
                              s(:masgn,
                                s(:array,
                                  s(:lasgn, :foo),
                                  s(:lasgn, :bar))))
      end

      it "works with multiple assignment with trailing comma" do
        _("for foo, in bar; end")
          .must_be_parsed_as s(:for,
                              s(:call, nil, :bar),
                              s(:masgn,
                                s(:array,
                                  s(:lasgn, :foo))))
      end
    end
  end
end
