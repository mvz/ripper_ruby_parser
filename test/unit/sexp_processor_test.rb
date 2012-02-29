require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::SexpProcessor do
  let :processor do
    RipperRubyParser::SexpProcessor.new
  end

  describe "#process" do
    it "can handle s(s()) constructs" do
      sexp = s(s())
      processor.process sexp
    end

    it "strips off the outer :program node" do
      skip
      sexp = s(:program, s(s(:foo)))
      result = processor.process sexp
      result.must_equal s(s(:foo))
    end
  end
end
