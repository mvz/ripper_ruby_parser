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

    describe "for a :program sexp" do
      it "strips off the outer :program node" do
        sexp = s(:program, s(s(:foo)))
        result = processor.process sexp
        result.must_equal s(:foo)
      end
    end

    describe "for a :string_literal sexp" do
      it "transforms a simple sexp to :str" do
        sexp = s(:string_literal, s(:string_content, s(:@tstring_content, "foo")))
        result = processor.process sexp
        result.must_equal s(:str, "foo")
      end
    end

    describe "for an :args_add_block sexp" do
      it "transforms a one-argument sexp to an :arglist" do
        sexp = s(:args_add_block, s(s(:foo)), false)
        result = processor.process sexp
        result.must_equal s(:arglist, s(:foo))
      end

      it "transforms a multi-argument sexp to an :arglist" do
        sexp = s(:args_add_block, s(s(:foo), s(:bar)), false)
        result = processor.process sexp
        result.must_equal s(:arglist, s(:foo), s(:bar))
      end

      it "processes nested sexps" do
        sexp = s(:args_add_block, s(s(:string_literal, s(:string_content, s(:@tstring_content, "foo")))), false)
        result = processor.process sexp
        result.must_equal s(:arglist, s(:str, "foo"))
      end
    end

    describe "for a :command sexp" do
      it "transforms a sexp to a :call" do
        sexp = s(:command, s(:@ident, "foo", s(1, 0)), s(:dummy_content))
        result = processor.process sexp
        result.must_equal s(:call, nil, :foo, s(:dummy_content))
      end

      it "processes nested sexps" do
        sexp = s(:command, s(:@ident, "foo", s(1, 0)), s(:args_add_block, s(s(:foo)), false))
        result = processor.process sexp
        result.must_equal s(:call, nil, :foo, s(:arglist, s(:foo)))
      end
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
