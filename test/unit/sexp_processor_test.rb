require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

class TestProcessor < RipperRubyParser::SexpProcessor
  def process_foo exp
    exp.shift
    s(:foo_p)
  end

  def process_bar exp
    exp.shift
    s(:bar_p)
  end
end

describe RipperRubyParser::SexpProcessor do
  let :processor do
    TestProcessor.new
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
        result.must_equal s(:foo_p)
      end

      it "transforms a multi-statement :program into a :block sexp" do
        sexp = s(:program, s(s(:foo), s(:bar)))
        result = processor.process sexp
        result.must_equal s(:block, s(:foo_p), s(:bar_p))
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
        result.must_equal s(:arglist, s(:foo_p))
      end

      it "transforms a multi-argument sexp to an :arglist" do
        sexp = s(:args_add_block, s(s(:foo), s(:bar)), false)
        result = processor.process sexp
        result.must_equal s(:arglist, s(:foo_p), s(:bar_p))
      end
    end

    describe "for a :command sexp" do
      it "transforms a sexp to a :call" do
        sexp = s(:command, s(:@ident, "foo", s(1, 0)), s(:foo))
        result = processor.process sexp
        result.must_equal s(:call, nil, :foo, s(:foo_p))
      end
    end

    describe "for a :var_ref sexp" do
      it "transforms the sexp to a :lvar sexp" do
        sexp = s(:var_ref, s(:@ident, "bar", s(1, 4)))
        result = processor.process sexp
        result.must_equal s(:lvar, :bar)
      end
    end

    describe "for a :module sexp" do
      it "does not create a nested :block sexp for an empty definition" do
        sexp = s(:module,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))),
                 s(:bodystmt, s(s(:void_stmt)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:module, :Foo, s(:scope))
      end

      it "does not create a nested :block sexp for a definition with one statement" do
        sexp = s(:module,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))),
                 s(:bodystmt, s(s(:foo)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:module, :Foo, s(:scope, s(:foo_p)))
      end

      it "creates a nested :block sexp for a definition with more than one statement" do
        sexp = s(:module,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))),
                 s(:bodystmt, s(s(:foo), s(:bar)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:module, :Foo,
                            s(:scope, s(:block, s(:foo_p), s(:bar_p))))
      end
    end

    describe "for a :class sexp" do
      it "does not create a nested :block sexp for an empty definition" do
        sexp = s(:class,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))), nil,
                 s(:bodystmt, s(s(:void_stmt)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:class, :Foo, nil, s(:scope))
      end

      it "does not create a nested :block sexp for a definition with one statement" do
        sexp = s(:class,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))), nil,
                 s(:bodystmt, s(s(:foo)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:class, :Foo, nil, s(:scope, s(:foo_p)))
      end

      it "creates a nested :block sexp for a definition with more than one statement" do
        sexp = s(:class,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))), nil,
                 s(:bodystmt, s(s(:foo), s(:bar)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:class,
                            :Foo, nil,
                            s(:scope, s(:block, s(:foo_p), s(:bar_p))))
      end

      it "passes on the given ancestor" do
        sexp = s(:class,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))),
                 s(:var_ref, s(:@const, "Bar", s(1, 12))),
                 s(:bodystmt, s(s(:void_stmt)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:class, :Foo, s(:const, :Bar), s(:scope))
      end
    end

    describe "for a :bodystmt sexp" do
      it "creates a :scope sexp with nested :block" do
        sexp = s(:bodystmt, s(s(:foo), s(:bar)), nil, nil, nil)
        result = processor.process sexp
        result.must_equal s(:scope, s(:block, s(:foo_p), s(:bar_p)))
      end

      it "removes nested :void_stmt sexps" do
        sexp = s(:bodystmt, s(s(:void_stmt), s(:foo)), nil, nil, nil)
        result = processor.process sexp
        result.must_equal s(:scope, s(:block, s(:foo_p)))
      end
    end

    describe "for a :def sexp" do
      it "transforms a sexp for a basic function definition" do
        sexp = s(:def,
                 s(:@ident, "foo", s(1, 4)),
                 s(:params, nil, nil, nil, nil, nil),
                 s(:bodystmt, s(s(:void_stmt)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:defn,
                            :foo, s(:args), s(:scope, s(:block, s(:nil))))

      end
    end

    describe "for an :assign sexp" do
      it "creates a :lasgn sexp" do
        sexp = s(:assign,
                 s(:var_field, s(:@ident, "a", s(1, 0))),
                 s(:@int, "1", s(1, 4)))
        result = processor.process sexp
        result.must_equal s(:lasgn, :a, s(:lit, 1))
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

  describe "#const_node_to_symbol" do
    it "processes a const sexp to a bare symbol" do
      sexp = s(:@const, "Foo", s(1, 0))
      result = processor.const_node_to_symbol sexp
      result.must_equal :Foo
    end
  end
end
