require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for method calls" do
      describe "without a receiver" do
        it "works without brackets" do
          "foo bar".
            must_be_parsed_as s(:call, nil, :foo,
                                s(:call, nil, :bar))
        end

        it "works with brackets" do
          "foo(bar)".
            must_be_parsed_as s(:call, nil, :foo,
                                s(:call, nil, :bar))
        end

        it "works with an empty parameter list and no brackets" do
          "foo".
            must_be_parsed_as s(:call, nil, :foo)
        end

        it "works with brackets around an empty parameter list" do
          "foo()".
            must_be_parsed_as s(:call, nil, :foo)
        end

        it "works for methods ending in a question mark" do
          "foo?".
            must_be_parsed_as s(:call, nil, :foo?)
        end

        it "works with nested calls without brackets" do
          "foo bar baz".
            must_be_parsed_as s(:call, nil, :foo,
                                s(:call, nil, :bar,
                                  s(:call, nil, :baz)))
        end

        it "works with a non-final splat argument" do
          "foo(bar, *baz, qux)".
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:splat, s(:call, nil, :baz)),
                                s(:call, nil, :qux))
        end

        it "works with a splat argument followed by several regular arguments" do
          "foo(bar, *baz, qux, quuz)".
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:splat, s(:call, nil, :baz)),
                                s(:call, nil, :qux),
                                s(:call, nil, :quuz))
        end
      end

      describe "with a receiver" do
        it "works without brackets" do
          "foo.bar baz".
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz))
        end

        it "works with brackets" do
          "foo.bar(baz)".
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz))
        end

        it "works with brackets around a call with no brackets" do
          "foo.bar(baz qux)".
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz,
                                  s(:call, nil, :qux)))
        end

        it "works with nested calls without brackets" do
          "foo.bar baz qux".
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz,
                                  s(:call, nil, :qux)))
        end
      end

      describe "with blocks" do
        it "works for a do block" do
          "foo.bar do baz; end".
            must_be_parsed_as s(:iter,
                                s(:call,
                                  s(:call, nil, :foo),
                                  :bar),
                                  s(:args),
                                  s(:call, nil, :baz))
        end

        it "works for a do block with several statements" do
          "foo.bar do baz; qux; end".
            must_be_parsed_as s(:iter,
                                s(:call,
                                  s(:call, nil, :foo),
                                  :bar),
                                  s(:args),
                                  s(:block,
                                    s(:call, nil, :baz),
                                    s(:call, nil, :qux)))
        end
      end
    end

    describe "for calls to super" do
      specify { "super".must_be_parsed_as s(:zsuper) }
      specify { "super foo".must_be_parsed_as s(:super,
                                                s(:call, nil, :foo)) }
      specify {
        "super foo, bar".must_be_parsed_as s(:super,
                                             s(:call, nil, :foo),
                                             s(:call, nil, :bar)) }
      specify {
        "super foo, *bar".must_be_parsed_as s(:super,
                                              s(:call, nil, :foo),
                                              s(:splat,
                                                s(:call, nil, :bar))) }
      specify {
        "super foo, *bar, &baz".
          must_be_parsed_as s(:super,
                              s(:call, nil, :foo),
                              s(:splat, s(:call, nil, :bar)),
                              s(:block_pass, s(:call, nil, :baz))) }
    end

    it "handles calling a proc" do
      "foo.()".
        must_be_parsed_as s(:call, s(:call, nil, :foo), :call)
    end
  end
end

