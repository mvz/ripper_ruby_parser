# frozen_string_literal: true

require File.expand_path("../../test_helper.rb", File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for character literals" do
      it "works for simple character literals" do
        _("?a")
          .must_be_parsed_as s(:str, "a")
      end

      it "works for escaped character literals" do
        _("?\\n")
          .must_be_parsed_as s(:str, "\n")
      end

      it "works for escaped character literals with ctrl" do
        _("?\\C-a")
          .must_be_parsed_as s(:str, "\u0001")
      end

      it "works for escaped character literals with meta" do
        _("?\\M-a")
          .must_be_parsed_as s(:str, (+"\xE1").force_encoding("ascii-8bit"))
      end

      it "works for escaped character literals with meta plus shorthand ctrl" do
        _("?\\M-\\ca")
          .must_be_parsed_as s(:str, (+"\x81").force_encoding("ascii-8bit"))
      end

      it "works for escaped character literals with shorthand ctrl plus meta" do
        _("?\\c\\M-a")
          .must_be_parsed_as s(:str, (+"\x81").force_encoding("ascii-8bit"))
      end

      it "works for escaped character literals with meta plus ctrl" do
        _("?\\M-\\C-a")
          .must_be_parsed_as s(:str, (+"\x81").force_encoding("ascii-8bit"))
      end

      it "works for escaped character literals with ctrl plus meta" do
        _("?\\C-\\M-a")
          .must_be_parsed_as s(:str, (+"\x81").force_encoding("ascii-8bit"))
      end
    end

    describe "for array literals" do
      it "works for an empty array" do
        _("[]")
          .must_be_parsed_as s(:array)
      end

      it "works for a simple case with splat" do
        _("[*foo]")
          .must_be_parsed_as s(:array,
                               s(:splat, s(:call, nil, :foo)))
      end

      it "works for a multi-element case with splat" do
        _("[foo, *bar]")
          .must_be_parsed_as s(:array,
                               s(:call, nil, :foo),
                               s(:splat, s(:call, nil, :bar)))
      end
    end

    describe "for hash literals" do
      it "works for an empty hash" do
        _("{}")
          .must_be_parsed_as s(:hash)
      end

      it "works for a hash with one pair" do
        _("{foo => bar}")
          .must_be_parsed_as s(:hash,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar))
      end

      it "works for a hash with multiple pairs" do
        _("{foo => bar, baz => qux}")
          .must_be_parsed_as s(:hash,
                               s(:call, nil, :foo),
                               s(:call, nil, :bar),
                               s(:call, nil, :baz),
                               s(:call, nil, :qux))
      end

      it "works for a hash with label keys" do
        _("{foo: bar, baz: qux}")
          .must_be_parsed_as s(:hash,
                               s(:lit, :foo),
                               s(:call, nil, :bar),
                               s(:lit, :baz),
                               s(:call, nil, :qux))
      end

      it "works for a hash with dynamic label keys" do
        _("{'foo': bar}")
          .must_be_parsed_as s(:hash,
                               s(:lit, :foo),
                               s(:call, nil, :bar))
      end

      it "works for a hash with splat" do
        _("{foo: bar, baz: qux, **quux}")
          .must_be_parsed_as s(:hash,
                               s(:lit, :foo), s(:call, nil, :bar),
                               s(:lit, :baz), s(:call, nil, :qux),
                               s(:kwsplat, s(:call, nil, :quux)))
      end

      it "works for shorthand hash syntax" do
        if RUBY_VERSION < "3.1.0"
          skip "This Ruby version does not support shorthand hash syntax"
        end
        _("{ foo: }")
          .must_be_parsed_as s(:hash, s(:lit, :foo), nil)
      end
    end

    describe "for number literals" do
      it "works for floats" do
        _("3.14")
          .must_be_parsed_as s(:lit, 3.14)
      end

      it "works for octal integer literals" do
        _("0700")
          .must_be_parsed_as s(:lit, 448)
      end

      it "handles negative sign for integers" do
        _("-1")
          .must_be_parsed_as s(:lit, -1)
      end

      it "handles space after negative sign for integers" do
        _("-1 ")
          .must_be_parsed_as s(:lit, -1)
      end

      it "handles negative sign for floats" do
        _("-3.14")
          .must_be_parsed_as s(:lit, -3.14)
      end

      it "handles space after negative sign for floats" do
        _("-3.14 ")
          .must_be_parsed_as s(:lit, -3.14)
      end

      it "handles positive sign" do
        _("+1")
          .must_be_parsed_as s(:lit, 1)
      end

      it "works for rationals" do
        _("1000r")
          .must_be_parsed_as s(:lit, 1000r)
      end

      it "works for imaginary numbers" do
        _("1i")
          .must_be_parsed_as s(:lit, 1i)
      end
    end
  end
end
