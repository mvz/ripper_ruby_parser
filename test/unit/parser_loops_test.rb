require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for the while statement" do
      it "works in the single-line postfix case" do
        "foo while bar".
          must_be_parsed_as s(:while,
                              s(:call, nil, :bar, s(:arglist)),
                              s(:call, nil, :foo, s(:arglist)), true)
      end

      it "works in the block postfix case" do
        "begin; foo; end while bar".
          must_be_parsed_as s(:while,
                              s(:call, nil, :bar, s(:arglist)),
                              s(:call, nil, :foo, s(:arglist)), false)
      end

      it "normalizes a negative condition" do
        "while not foo; bar; end".
          must_be_parsed_as s(:until,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:call, nil, :bar, s(:arglist)), true)
      end
    end

    describe "for the until statement" do
      it "normalizes a negative condition" do
        "until not foo; bar; end".
          must_be_parsed_as s(:while,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:call, nil, :bar, s(:arglist)), true)

      end
    end
  end
end
