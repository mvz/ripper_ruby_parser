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

    it "transforms a one-argument :args_add_block to an :arglist" do
      sexp = s(:args_add_block, s(s(:foo)), false)
      result = processor.process sexp
      result.must_equal s(:arglist, s(:foo))
    end

    it "transforms a multi-argument :args_add_block to an :arglist" do
      sexp = s(:args_add_block, s(s(:foo), s(:bar)), false)
      result = processor.process sexp
      result.must_equal s(:arglist, s(:foo), s(:bar))
    end

    it "processes sexps inside :args_add_block" do
      sexp = s(:args_add_block, s(s(:string_literal, s(:string_content, s(:@tstring_content, "foo")))), false)
      result = processor.process sexp
      result.must_equal s(:arglist, s(:str, "foo"))
    end

    it "transforms a :command to a :call" do
      sexp = s(:command, s(:@ident, "foo", s(1, 0)), s(:dummy_content))
      result = processor.process sexp
      result.must_equal s(:call, nil, :foo, s(:dummy_content))
    end

    it "processes sexps inside :command" do
      sexp = s(:command, s(:@ident, "foo", s(1, 0)), s(:args_add_block, s(s(:foo)), false))
      result = processor.process sexp
      result.must_equal s(:call, nil, :foo, s(:arglist, s(:foo)))
    end
  end

  describe "#identifier_node_to_symbol" do
    it "processes an identifier sexp to a bare symbol" do
      sexp = s(:@ident, "foo", s(1, 0))
      result = processor.identifier_node_to_symbol sexp
      result.must_equal :foo
    end
  end
end
