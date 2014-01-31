require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for postfix if" do
      it "handles negative conditions" do
        "foo if not bar".
          must_be_parsed_as s(:if,
                              s(:call, s(:call, nil, :bar), :!),
                              s(:call, nil, :foo),
                              nil)
      end
    end

    describe "for case" do
      it "emulates RubyParser's strange handling of splat" do
        "case foo; when *bar; baz; end".
          must_be_parsed_as s(:case, s(:call, nil, :foo),
                              s(:when,
                                s(:array,
                                  s(:when, s(:call, nil, :bar),
                                  nil)),
                                s(:call, nil, :baz)),
                              nil)

      end
    end
  end
end
