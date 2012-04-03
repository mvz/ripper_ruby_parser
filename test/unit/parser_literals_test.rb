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
      end
    end
  end
end
