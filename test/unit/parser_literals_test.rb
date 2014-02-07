# coding: utf-8
require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for regexp literals" do
      it "works with the no-encoding flag" do
        parser = RipperRubyParser::Parser.new
        result = parser.parse "/foo/n"
        # Use inspect since regular == finds no difference between /foo/n
        # and /foo/
        result.inspect.must_equal s(:lit, /foo/n).inspect
      end

      describe "with interpolations" do
        it "works with the no-encoding flag" do
          '/foo#{bar}/n'.
            must_be_parsed_as s(:dregx,
                                "foo",
                                s(:evstr,
                                  s(:call, nil, :bar)), 32)
        end

        it "works with the unicode-encoding flag" do
          '/foo#{bar}/u'.
            must_be_parsed_as s(:dregx,
                                "foo",
                                s(:evstr,
                                  s(:call, nil, :bar)), 16)
        end

        it "works with the euc-encoding flag" do
          '/foo#{bar}/e'.
            must_be_parsed_as s(:dregx,
                                "foo",
                                s(:evstr,
                                  s(:call, nil, :bar)), 16)
        end

        it "works with the sjis-encoding flag" do
          '/foo#{bar}/s'.
            must_be_parsed_as s(:dregx,
                                "foo",
                                s(:evstr,
                                  s(:call, nil, :bar)), 16)
        end

        describe "containing just a literal string" do
          it "performs the interpolation when it is at the end" do
            '/foo#{"bar"}/'.must_be_parsed_as s(:lit, /foobar/)
          end

          it "performs the interpolation when it is in the middle" do
            '/foo#{"bar"}baz/'.must_be_parsed_as s(:lit, /foobarbaz/)
          end

          it "performs the interpolation when it is at the start" do
            '/#{"foo"}bar/'.must_be_parsed_as s(:lit, /foobar/)
          end
        end
      end
    end

    describe "for string literals" do
      describe "with escape sequences" do
        it "works with hex escapes" do
          "\"\\x36\"".must_be_parsed_as s(:str, "6")
          "\"\\x4a\"".must_be_parsed_as s(:str, "J")
          "\"\\x4A\"".must_be_parsed_as s(:str, "J")
          "\"\\x3Z\"".must_be_parsed_as s(:str, "\x03Z")
        end

        it "works with single-letter escapes" do
          "\"foo\\abar\"".must_be_parsed_as s(:str, "foo\abar")
          "\"foo\\bbar\"".must_be_parsed_as s(:str, "foo\bbar")
          "\"foo\\ebar\"".must_be_parsed_as s(:str, "foo\ebar")
          "\"foo\\fbar\"".must_be_parsed_as s(:str, "foo\fbar")
          "\"foo\\nbar\"".must_be_parsed_as s(:str, "foo\nbar")
          "\"foo\\rbar\"".must_be_parsed_as s(:str, "foo\rbar")
          "\"foo\\sbar\"".must_be_parsed_as s(:str, "foo\sbar")
          "\"foo\\tbar\"".must_be_parsed_as s(:str, "foo\tbar")
          "\"foo\\vbar\"".must_be_parsed_as s(:str, "foo\vbar")
        end

        it "works with octal number escapes" do
          "\"foo\\123bar\"".must_be_parsed_as s(:str, "foo\123bar")
          "\"foo\\23bar\"".must_be_parsed_as s(:str, "foo\023bar")
          "\"foo\\3bar\"".must_be_parsed_as s(:str, "foo\003bar")

          "\"foo\\118bar\"".must_be_parsed_as s(:str, "foo\0118bar")
          "\"foo\\18bar\"".must_be_parsed_as s(:str, "foo\0018bar")
        end

        it "works with simple short hand control sequence escapes" do
          "\"foo\\cabar\"".must_be_parsed_as s(:str, "foo\cabar")
          "\"foo\\cZbar\"".must_be_parsed_as s(:str, "foo\cZbar")
        end

        it "works with simple regular control sequence escapes" do
          "\"foo\\C-abar\"".must_be_parsed_as s(:str, "foo\C-abar")
          "\"foo\\C-Zbar\"".must_be_parsed_as s(:str, "foo\C-Zbar")
        end

        # TODO: Implement remaining escape sequence cases.

        # TODO: Behave differently in extra_compatible mode.
        it "works with unicode escapes (unlike RubyParser)" do
          "\"foo\\u273bbar\"".must_be_parsed_as s(:str, "foo✻bar")
        end
      end

      describe "with interpolations" do
        describe "containing just a literal string" do
          it "performs the interpolation when it is at the end" do
            '"foo#{"bar"}"'.must_be_parsed_as s(:str, "foobar")
          end

          it "performs the interpolation when it is in the middle" do
            '"foo#{"bar"}baz"'.must_be_parsed_as s(:str, "foobarbaz")
          end

          it "performs the interpolation when it is at the start" do
            '"#{"foo"}bar"'.must_be_parsed_as s(:str, "foobar")
          end
        end

        describe "without braces" do
          it "works for ivars" do
            "\"foo\#@bar\"".must_be_parsed_as s(:dstr,
                                                "foo",
                                                s(:evstr, s(:ivar, :@bar)))
          end

          it "works for gvars" do
            "\"foo\#$bar\"".must_be_parsed_as s(:dstr,
                                                "foo",
                                                s(:evstr, s(:gvar, :$bar)))
          end

          it "works for cvars" do
            "\"foo\#@@bar\"".must_be_parsed_as s(:dstr,
                                                "foo",
                                                s(:evstr, s(:cvar, :@@bar)))
          end
        end

        describe "with braces" do
          it "correctly handles two interpolations in a row" do
            "\"\#{bar}\#{qux}\"".
              must_be_parsed_as s(:dstr,
                                  "",
                                  s(:evstr, s(:call, nil, :bar)),
                                  s(:evstr, s(:call, nil, :qux)))
          end
        end
      end

      describe "with string concatenation" do
        it "performs the concatenation in the case of two simple literal strings" do
          "\"foo\" \"bar\"".must_be_parsed_as s(:str, "foobar")
        end

        it "performs the concatenation when the right string has interpolations" do
          "\"foo\" \"bar\#{baz}\"".
            must_be_parsed_as s(:dstr,
                                "foobar",
                                s(:evstr, s(:call, nil, :baz)))
        end

        it "performs the concatenation when the left string has interpolations" do
          "\"foo\#{bar}\" \"baz\"".
            must_be_parsed_as s(:dstr,
                                "foo",
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, "baz"))
        end

        it "performs the concatenation when both strings have interpolations" do
          "\"foo\#{bar}\" \"baz\#{qux}\"".
            must_be_parsed_as s(:dstr,
                                "foo",
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, "baz"),
                                s(:evstr, s(:call, nil, :qux)))
        end

        it "removes empty substrings from the concatenation when both strings have interpolations" do
          "\"foo\#{bar}\" \"\#{qux}\"".
            must_be_parsed_as s(:dstr,
                                "foo",
                                s(:evstr, s(:call, nil, :bar)),
                                s(:evstr, s(:call, nil, :qux)))
        end
      end
    end

    describe "for word list literals" do
      it "correctly handles interpolation" do
        "%W(foo \#{bar} baz)".
          must_be_parsed_as  s(:array,
                               s(:str, "foo"),
                               s(:dstr, "", s(:evstr, s(:call, nil, :bar))),
                               s(:str, "baz"))
      end

      it "correctly handles braceless interpolation" do
        "%W(foo \#@bar baz)".
          must_be_parsed_as  s(:array,
                               s(:str, "foo"),
                               s(:dstr, "", s(:evstr, s(:ivar, :@bar))),
                               s(:str, "baz"))
      end
    end

    describe "for character literals" do
      it "works for simple character literals" do
        "?a".
          must_be_parsed_as s(:str, "a")
      end

      it "works for escaped character literals" do
        "?\\n".
          must_be_parsed_as s(:str, "\n")
      end

      it "works for escaped character literals with ctrl" do
        "?\\C-a".
          must_be_parsed_as s(:str, "\u0001")
      end

      it "works for escaped character literals with meta" do
        "?\\M-a".
          must_be_parsed_as s(:str, "\xE1".force_encoding("ascii-8bit"))
      end

      it "works for escaped character literals with meta plus shorthand ctrl" do
        "?\\M-\\ca".
          must_be_parsed_as s(:str, "\x81".force_encoding("ascii-8bit"))
      end

      it "works for escaped character literals with shorthand ctrl plus meta" do
        "?\\c\\M-a".
          must_be_parsed_as s(:str, "\x81".force_encoding("ascii-8bit"))
      end

      it "works for escaped character literals with meta plus ctrl" do
        "?\\M-\\C-a".
          must_be_parsed_as s(:str, "\x81".force_encoding("ascii-8bit"))
      end

      it "works for escaped character literals with ctrl plus meta" do
        "?\\C-\\M-a".
          must_be_parsed_as s(:str, "\x81".force_encoding("ascii-8bit"))
      end
    end
  end
end
