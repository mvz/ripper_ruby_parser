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

    it "can handle line number information constructs" do
      sexp = s(1, 6)
      processor.process sexp
    end

    it "strips off the outer :program node" do
      sexp = s(:program, s(s(:foo)))
      result = processor.process sexp
      result.must_equal s(:foo)
    end

    it "transforms a simple :string_literal to :str" do
      sexp = s(:string_literal, s(:string_content, s(:@tstring_content, "foo")))
      result = processor.process sexp
      result.must_equal s(:str, "foo")
    end

    it "transforms an :args_add_block to an :arglist" do
      skip
      sexp = s(:args_add_block, s(s(:string_literal, s(:string_content, s(:@tstring_content, "Hello World", s(1, 6))))), false)
    end
  end
end
