require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for single assignment" do
      it "works when assigning to a namespaced constant" do
        "Foo::Bar = baz".
          must_be_parsed_as s(:cdecl,
                              s(:colon2, s(:const, :Foo), :Bar),
                              s(:call, nil, :baz))
      end

      it "works when assigning to constant in the root namespace" do
        "::Foo = bar".
          must_be_parsed_as s(:cdecl,
                              s(:colon3, :Foo),
                              s(:call, nil, :bar))
      end

      describe "with a right-hand splat" do
        specify do
          "foo = *bar".
            must_be_parsed_as s(:lasgn, :foo,
                                s(:svalue,
                                  s(:splat,
                                    s(:call, nil, :bar))))
        end

        specify do
          "foo = bar, *baz".
            must_be_parsed_as s(:lasgn, :foo,
                                s(:svalue,
                                  s(:array,
                                    s(:call, nil, :bar),
                                    s(:splat,
                                      s(:call, nil, :baz)))))
        end
      end

      describe "with several items on the right hand side" do
        specify do
          "foo = bar, baz".
            must_be_parsed_as s(:lasgn, :foo,
                                s(:svalue,
                                  s(:array,
                                    s(:call, nil, :bar),
                                    s(:call, nil, :baz))))
        end
      end

      describe "with an array literal on the right hand side" do
        specify do
          "foo = [bar, baz]".
            must_be_parsed_as s(:lasgn, :foo,
                                s(:array,
                                  s(:call, nil, :bar),
                                  s(:call, nil, :baz)))
        end
      end
    end

    describe "for multiple assignment" do
      specify do
        "foo, * = bar".
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:splat)),
                              s(:to_ary, s(:call, nil, :bar)))
      end

      specify do
        "(foo, *bar) = baz".
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:lasgn, :foo),
                                s(:splat, s(:lasgn, :bar))),
                              s(:to_ary, s(:call, nil, :baz)))
      end
    end

    describe "for assignment to a collection element" do
      it "handles multiple indices" do
        "foo[bar, baz] = qux".
          must_be_parsed_as s(:attrasgn,
                              s(:call, nil, :foo),
                              :[]=,
                              s(:call, nil, :bar),
                              s(:call, nil, :baz),
                              s(:call, nil, :qux))
      end
    end

    describe "for operator assignment" do
      describe "assigning to a collection element" do
        it "handles multiple indices" do
          "foo[bar, baz] += qux".
            must_be_parsed_as s(:op_asgn1,
                                s(:call, nil, :foo),
                                s(:arglist,
                                  s(:call, nil, :bar),
                                  s(:call, nil, :baz)),
                                :+,
                                s(:call, nil, :qux))
        end

        it "works with &&=" do
          "foo &&= bar".
            must_be_parsed_as s(:op_asgn_and,
                                s(:lvar, :foo), s(:lasgn, :foo, s(:call, nil, :bar)))
        end
      end
    end

    describe "for multiple assignment" do
      describe "with a right-hand splat" do
        specify do
          "foo, bar = *baz".
            must_be_parsed_as s(:masgn,
                                s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                                s(:splat, s(:call, nil, :baz)))
        end
        specify do
          "foo, bar = baz, *qux".
            must_be_parsed_as s(:masgn,
                                s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                                s(:array,
                                  s(:call, nil, :baz),
                                  s(:splat, s(:call, nil, :qux))))
        end
      end
    end
  end
end
