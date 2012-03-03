require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  let(:parser) { RipperRubyParser::Parser.new }
  describe "#parse" do
    it "returns an s-expression" do
      result = parser.parse "foo"
      result.must_be_instance_of Sexp
    end

    it "post-processes its result with the passed sexp processor" do
      sexp_p = MiniTest::Mock.new
      sexp_p.expect :process, s(:result), [Sexp]

      parser = RipperRubyParser::Parser.new sexp_p
      result = parser.parse "any code"

      result.must_equal s(:result)
      sexp_p.verify
    end

    describe "for unless" do
      it "works in the postfix case" do
        result = parser.parse "foo unless bar"
        result.must_equal s(:if,
                            s(:call, nil, :bar, s(:arglist)),
                            nil,
                            s(:call, nil, :foo, s(:arglist)))
      end

      it "works in the block case" do
        result = parser.parse "unless bar; foo; end"
        result.must_equal s(:if,
                            s(:call, nil, :bar, s(:arglist)),
                            nil,
                            s(:call, nil, :foo, s(:arglist)))
      end
    end

    describe "for identifiers" do
      it "works for an ivar" do
        result = parser.parse "@foo"
        result.must_equal s(:ivar, :@foo)
      end

      it "works for self" do
        result = parser.parse "self"
        result.must_equal s(:self)
      end
    end

    describe "for arguments" do
      it "works for a simple case with splat" do
        result = parser.parse "foo *bar"
        result.must_equal s(:call,
                            nil,
                            :foo,
                            s(:arglist,
                              s(:splat, s(:call, nil, :bar, s(:arglist)))))
      end

      it "works for a multi-argument case with splat" do
        result = parser.parse "foo bar, *baz"
        result.must_equal s(:call,
                            nil,
                            :foo,
                            s(:arglist,
                              s(:call, nil, :bar, s(:arglist)),
                              s(:splat, s(:call, nil, :baz, s(:arglist)))))
      end
    end

    describe "for arrays" do
      it "works for a simple case with splat" do
        result = parser.parse "[*foo]"
        result.must_equal s(:array,
                            s(:splat, s(:call, nil, :foo, s(:arglist))))
      end

      it "works for a multi-element case with splat" do
        result = parser.parse "[foo, *bar]"
        result.must_equal s(:array,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:splat, s(:call, nil, :bar, s(:arglist))))
      end
    end

    describe "for method definitions" do
      it "works with def with reciever" do
        result = parser.parse "def foo.bar; end"
        result.must_equal s(:defs,
                            s(:call, nil, :foo, s(:arglist)),
                            :bar,
                            s(:args), s(:scope, s(:block)))
      end

      it "works with a method argument with a default value" do
        result = parser.parse "def foo bar=nil; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args, :bar, s(:block, s(:lasgn, :bar, s(:nil)))),
                            s(:scope, s(:block, s(:nil))))
      end

      it "works with several method arguments with default values" do
        result = parser.parse "def foo bar=1, baz=2; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args,
                              :bar, :baz,
                              s(:block,
                                s(:lasgn, :bar, s(:lit, 1)),
                                s(:lasgn, :baz, s(:lit, 2)))),
                            s(:scope, s(:block, s(:nil))))
      end
    end

    describe "for method calls" do
      describe "without a reciever" do
        it "works without brackets" do
          result = parser.parse "foo bar"
          result.must_equal s(:call, nil, :foo,
                              s(:arglist, s(:call, nil, :bar, s(:arglist))))
        end

        it "works with brackets" do
          result = parser.parse "foo(bar)"
          result.must_equal s(:call, nil, :foo,
                              s(:arglist, s(:call, nil, :bar, s(:arglist))))
        end
      end

      describe "with a reciever" do
        it "works without brackets" do
          result = parser.parse "foo.bar baz"
          result.must_equal s(:call,
                              s(:call, nil, :foo, s(:arglist)),
                              :bar,
                              s(:arglist, s(:call, nil, :baz, s(:arglist))))
        end

        it "works with brackets" do
          result = parser.parse "foo.bar(baz)"
          result.must_equal s(:call,
                              s(:call, nil, :foo, s(:arglist)),
                              :bar,
                              s(:arglist, s(:call, nil, :baz, s(:arglist))))
        end
      end

      describe "with blocks" do
        it "works for a do block" do
          result = parser.parse "foo.bar do baz; end"
          result.must_equal s(:iter,
                              s(:call,
                                s(:call, nil, :foo, s(:arglist)),
                                :bar,
                                s(:arglist)),
                              nil,
                              s(:call, nil, :baz, s(:arglist)))
        end
      end
    end
  end
end
