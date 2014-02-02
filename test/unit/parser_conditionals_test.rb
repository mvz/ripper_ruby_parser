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

    describe "for case block" do
      it "works with a single when clause" do
        "case foo; when bar; baz; end".
          must_be_parsed_as s(:case,
                              s(:call, nil, :foo),
                              s(:when,
                                s(:array, s(:call, nil, :bar)),
                                s(:call, nil, :baz)),
                              nil)
      end

      it "works with multiple when clauses" do
        "case foo; when bar; baz; when qux; quux; end".
          must_be_parsed_as s(:case,
                              s(:call, nil, :foo),
                              s(:when,
                                s(:array, s(:call, nil, :bar)),
                                s(:call, nil, :baz)),
                              s(:when,
                                s(:array, s(:call, nil, :qux)),
                                s(:call, nil, :quux)),
                              nil)
      end

      it "works with multiple statements in the when block" do
        "case foo; when bar; baz; qux; end".
          must_be_parsed_as s(:case,
                              s(:call, nil, :foo),
                              s(:when,
                                s(:array, s(:call, nil, :bar)),
                                s(:call, nil, :baz),
                                s(:call, nil, :qux)),
                              nil)
      end

      it "works with an else clause" do
        "case foo; when bar; baz; else; qux; end".
          must_be_parsed_as s(:case,
                              s(:call, nil, :foo),
                              s(:when,
                                s(:array, s(:call, nil, :bar)),
                                s(:call, nil, :baz)),
                              s(:call, nil, :qux))
      end
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
