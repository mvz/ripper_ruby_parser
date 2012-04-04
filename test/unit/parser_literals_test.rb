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
                                  s(:call, nil, :bar, s(:arglist))), 32)
        end

        it "works with the unicode-encoding flag" do
          '/foo#{bar}/u'.
            must_be_parsed_as s(:dregx,
                                "foo",
                                s(:evstr,
                                  s(:call, nil, :bar, s(:arglist))), 16)
        end

        it "works with the euc-encoding flag" do
          '/foo#{bar}/e'.
            must_be_parsed_as s(:dregx,
                                "foo",
                                s(:evstr,
                                  s(:call, nil, :bar, s(:arglist))), 16)
        end

        it "works with the sjis-encoding flag" do
          '/foo#{bar}/s'.
            must_be_parsed_as s(:dregx,
                                "foo",
                                s(:evstr,
                                  s(:call, nil, :bar, s(:arglist))), 16)
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
          "\"\\xAF\"".must_be_parsed_as s(:str, "\xAF")
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
      end
    end
  end
end
