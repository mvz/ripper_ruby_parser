require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for block parameters" do
      specify do
        "foo do |(bar, baz)| end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:masgn,
                                s(:array,
                                  s(:lasgn, :bar),
                                  s(:lasgn, :baz))))
      end

      specify do
        "foo do |(bar, *baz)| end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:masgn,
                                s(:array,
                                  s(:lasgn, :bar),
                                  s(:splat, s(:lasgn, :baz)))))
      end

      specify do
        "foo do |bar,*| end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:masgn, s(:array, s(:lasgn, :bar), s(:splat))))
      end

      it "behaves differently from RubyParser with a trailing comma in the block parameters" do
        "foo do |bar, | end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:lasgn, :bar))
      end
    end
  end
end
