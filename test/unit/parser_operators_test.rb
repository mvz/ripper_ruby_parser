require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for negated operators" do
      specify do
        "foo !~ bar".must_be_parsed_as s(:not,
                                         s(:call,
                                           s(:call, nil, :foo),
                                           :=~,
                                           s(:call, nil, :bar)))
      end
    end

    describe "for boolean operators" do
      it "handles triple :and" do
        "foo and bar and baz and qux".
          must_be_parsed_as s(:and,
                              s(:call, nil, :foo),
                              s(:and,
                                s(:call, nil, :bar),
                                s(:and,
                                  s(:call, nil, :baz),
                                  s(:call, nil, :qux))))
      end
    end
  end
end
