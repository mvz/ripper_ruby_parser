require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for negated operators" do
      specify do
        "foo !~ bar".must_be_parsed_as s(:not,
                                         s(:call,
                                           s(:call, nil, :foo, s(:arglist)),
                                           :=~,
                                           s(:arglist,
                                             s(:call, nil, :bar, s(:arglist)))))
      end
    end

    describe "for boolean operators" do
      it "handles triple :and" do
        "foo and bar and baz and qux".
          must_be_parsed_as s(:and,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:and,
                                s(:call, nil, :bar, s(:arglist)),
                                s(:and,
                                  s(:call, nil, :baz, s(:arglist)),
                                  s(:call, nil, :qux, s(:arglist)))))
      end
    end
  end
end
