require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for multiple assignment" do
      specify do
        "foo, * = bar".
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:splat)),
                              s(:to_ary, s(:call, nil, :bar, s(:arglist))))
      end

      specify do
        "(foo, *bar) = baz".
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:lasgn, :foo),
                                s(:splat, s(:lasgn, :bar))),
                              s(:to_ary, s(:call, nil, :baz, s(:arglist))))
      end
    end
  end
end
