require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for the while statement" do
      it "works in the single-line postfix case" do
        "foo while bar".
          must_be_parsed_as s(:while,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo), true)
      end

      it "works in the block postfix case" do
        "begin; foo; end while bar".
          must_be_parsed_as s(:while,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo), false)
      end

      it "handles a negative condition" do
        "while not foo; bar; end".
          must_be_parsed_as s(:while,
                              s(:call, s(:call, nil, :foo), :!),
                              s(:call, nil, :bar), true)
      end

      it "handles a negative condition in the postfix case" do
        "foo while not bar".
          must_be_parsed_as s(:while,
                              s(:call, s(:call, nil, :bar), :!),
                              s(:call, nil, :foo), true)
      end
    end

    describe "for the until statement" do
      it "handles a negative condition" do
        "until not foo; bar; end".
          must_be_parsed_as s(:until,
                              s(:call, s(:call, nil, :foo), :!),
                              s(:call, nil, :bar), true)
      end

      it "handles a negative condition in the postfix case" do
        "foo until not bar".
          must_be_parsed_as s(:until,
                              s(:call, s(:call, nil, :bar), :!),
                              s(:call, nil, :foo), true)
      end
    end
  end
end
