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

  def process_baz exp
    exp.shift
    s(:baz_p)
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

    if false
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
    end

    describe "for a :command sexp" do
      it "transforms a sexp to a :call" do
        sexp = s(:command, s(:@ident, "foo", s(1, 0)), s(:arglist, s(:foo)))
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

    describe "for a :vcall sexp" do
      it "transforms the sexp to a :call sexp" do
        sexp = s(:vcall, s(:@ident, "bar", s(1, 4)))
        result = processor.process sexp
        result.must_equal s(:call, nil, :bar)
      end
    end

    describe "for a :module sexp" do
      it "does not create body eleents for an empty definition" do
        sexp = s(:module,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))),
                 s(:bodystmt, s(s(:void_stmt)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:module, :Foo)
      end

      it "creates a single body element for a definition with one statement" do
        sexp = s(:module,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))),
                 s(:bodystmt, s(s(:foo)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:module, :Foo, s(:foo_p))
      end

      it "creates multiple body elements for a definition with more than one statement" do
        sexp = s(:module,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))),
                 s(:bodystmt, s(s(:foo), s(:bar)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:module, :Foo, s(:foo_p), s(:bar_p))
      end
    end

    describe "for a :class sexp" do
      it "does not create body eleents for an empty definition" do
        sexp = s(:class,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))), nil,
                 s(:bodystmt, s(s(:void_stmt)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:class, :Foo, nil)
      end

      it "creates a single body element for a definition with one statement" do
        sexp = s(:class,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))), nil,
                 s(:bodystmt, s(s(:foo)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:class, :Foo, nil, s(:foo_p))
      end

      it "creates multiple body elements for a definition with more than one statement" do
        sexp = s(:class,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))), nil,
                 s(:bodystmt, s(s(:foo), s(:bar)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:class, :Foo, nil, s(:foo_p), s(:bar_p))
      end

      it "passes on the given ancestor" do
        sexp = s(:class,
                 s(:const_ref, s(:@const, "Foo", s(1, 13))),
                 s(:var_ref, s(:@const, "Bar", s(1, 12))),
                 s(:bodystmt, s(s(:void_stmt)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:class, :Foo, s(:const, :Bar))
      end
    end

    describe "for a :bodystmt sexp" do
      it "creates a :scope sexp with nested :block" do
        sexp = s(:bodystmt, s(s(:foo), s(:bar)), nil, nil, nil)
        result = processor.process sexp
        result.must_equal s(s(:block, s(:foo_p), s(:bar_p)))
      end

      it "removes nested :void_stmt sexps" do
        sexp = s(:bodystmt, s(s(:void_stmt), s(:foo)), nil, nil, nil)
        result = processor.process sexp
        result.must_equal s(s(:foo_p))
      end
    end

    describe "for a :def sexp" do
      it "transforms the sexp for a basic function definition" do
        sexp = s(:def,
                 s(:@ident, "foo", s(1, 4)),
                 s(:params, nil, nil, nil, nil, nil),
                 s(:bodystmt, s(s(:void_stmt)), nil, nil, nil))
        result = processor.process sexp
        result.must_equal s(:defn, :foo, s(:args), s(:nil))

      end
    end

    describe "for a :params sexp" do
      describe "with a normal arguments" do
        it "creates :lvar sexps" do
          sexp =  s(:params, s(s(:@ident, "bar", s(1, 8))), nil, nil, nil, nil)
          result = processor.process sexp
          result.must_equal s(:args, s(:lvar, :bar))
        end
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

    describe "for a :binary sexp" do
      it "creates a :call sexp" do
        sexp = s(:binary, s(:bar), :==, s(:foo))
        result = processor.process sexp
        result.must_equal s(:call, s(:bar_p), :==, s(:foo_p))
      end
    end

    describe "for a :method_add_block sexp" do
      it "creates an :iter sexp" do
        sexp = s(:method_add_block,
                 s(:call, s(:foo), :".", s(:@ident, "baz", s(1, 2))),
                 s(:brace_block, nil, s(s(:bar))))
        result = processor.process sexp
        result.must_equal s(:iter,
                            s(:call, s(:foo_p), :baz), s(:args),
                            s(:bar_p))
      end

      describe "with a block parameter" do
        it "creates an :iter sexp with an :args sexp for the block parameter" do
          sexp = s(:method_add_block,
                   s(:call, s(:foo), :".", s(:@ident, "baz", s(1, 2))),
                   s(:brace_block,
                     s(:block_var,
                       s(:params, s(s(:@ident, "i", s(1, 6))), nil, nil, nil, nil),
                       nil),
                     s(s(:bar))))
          result = processor.process sexp
          result.must_equal s(:iter,
                              s(:call, s(:foo_p), :baz),
                              s(:args, :i),
                              s(:bar_p))
        end
      end
    end

    describe "for an :if sexp" do
      describe "with a single statement in the if body" do
        it "uses the statement sexp as the body" do
          sexp = s(:if, s(:foo), s(s(:bar)), nil)
          result = processor.process sexp
          result.must_equal s(:if, s(:foo_p), s(:bar_p), nil)
        end
      end

      describe "with multiple statements in the if body" do
        it "uses a block containing the statement sexps as the body" do
          sexp = s(:if, s(:foo), s(s(:bar), s(:baz)), nil)
          result = processor.process sexp
          result.must_equal s(:if, s(:foo_p), s(:block, s(:bar_p), s(:baz_p)), nil)
        end
      end
    end

    describe "for an :array sexp" do
      it "pulls up the element sexps" do
        sexp = s(:array, s(s(:foo), s(:bar), s(:baz)))
        result = processor.process sexp
        result.must_equal s(:array, s(:foo_p), s(:bar_p), s(:baz_p))
      end
    end

    describe "for a :const_path_ref sexp" do
      it "returns a :colon2 sexp" do
        sexp = s(:const_path_ref,
                 s(:var_ref, s(:@const, "Foo", s(1, 0))),
                 s(:@const, "Bar", s(1, 5)))
        result = processor.process sexp
        result.must_equal s(:colon2, s(:const, :Foo), :Bar)
      end
    end

    describe "for a :when sexp" do
      it "turns nested :when clauses into a list" do
        sexp = s(:when, s(s(:foo)), s(s(:bar)),
                 s(:when, s(s(:foo)), s(s(:bar)),
                   s(:when, s(s(:foo)), s(s(:bar)), nil)))
        result = processor.process sexp
        result.must_equal s(s(:when, s(:array, s(:foo_p)), s(:bar_p)),
                            s(:when, s(:array, s(:foo_p)), s(:bar_p)),
                            s(:when, s(:array, s(:foo_p)), s(:bar_p)),
                            nil)
      end
    end
  end

  describe "#extract_node_symbol" do
    it "processes an identifier sexp to a bare symbol" do
      sexp = s(:@ident, "foo", s(1, 0))
      result = processor.send :extract_node_symbol, sexp
      result.must_equal :foo
    end

    it "processes a const sexp to a bare symbol" do
      sexp = s(:@const, "Foo", s(1, 0))
      result = processor.send :extract_node_symbol, sexp
      result.must_equal :Foo
    end
  end

  describe "#trickle_up_line_numbers" do
    it "works through several nested levels" do
      inner = s(:foo)
      outer = s(:bar, s(:baz, s(:qux, inner)))
      outer.line = 42
      processor.send :trickle_down_line_numbers, outer
      inner.line.must_equal 42
    end
  end

  describe "#trickle_down_line_numbers" do
    it "works through several nested levels" do
      inner = s(:foo)
      inner.line = 42
      outer = s(:bar, s(:baz, s(:qux, inner)))
      processor.send :trickle_up_line_numbers, outer
      outer.line.must_equal 42
    end
  end
end
