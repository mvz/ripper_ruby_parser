require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for regular if" do
      it "handles bare regex literal in condition" do
        "if /foo/; bar; end".
          must_be_parsed_as s(:if,
                              s(:match, s(:lit, /foo/)),
                              s(:call, nil, :bar),
                              nil)
      end

      it "handles interpolated regex in condition" do
        'if /#{foo}/; bar; end'.
          must_be_parsed_as s(:if,
                              s(:dregx, "", s(:evstr, s(:call, nil, :foo))),
                              s(:call, nil, :bar),
                              nil)
      end
    end

    describe "for postfix if" do
      it "handles negative conditions" do
        "foo if not bar".
          must_be_parsed_as s(:if,
                              s(:call, s(:call, nil, :bar), :!),
                              s(:call, nil, :foo),
                              nil)
      end

      it "handles bare regex literal in condition" do
        "foo if /bar/".
          must_be_parsed_as s(:if,
                              s(:match, s(:lit, /bar/)),
                              s(:call, nil, :foo),
                              nil)
      end

      it "handles interpolated regex in condition" do
        'foo if /#{bar}/'.
          must_be_parsed_as s(:if,
                              s(:dregx, "", s(:evstr, s(:call, nil, :bar))),
                              s(:call, nil, :foo),
                              nil)
      end
    end

    describe "for regular unless" do
      it "handles bare regex literal in condition" do
        "unless /foo/; bar; end".
          must_be_parsed_as s(:if,
                              s(:match, s(:lit, /foo/)),
                              nil,
                              s(:call, nil, :bar))
      end

      it "handles interpolated regex in condition" do
        'unless /#{foo}/; bar; end'.
          must_be_parsed_as s(:if,
                              s(:dregx, "", s(:evstr, s(:call, nil, :foo))),
                              nil,
                              s(:call, nil, :bar))
      end
    end

    describe "for postfix unless" do
      it "handles bare regex literal in condition" do
        "foo unless /bar/".
          must_be_parsed_as s(:if,
                              s(:match, s(:lit, /bar/)),
                              nil,
                              s(:call, nil, :foo))
      end

      it "handles interpolated regex in condition" do
        'foo unless /#{bar}/'.
          must_be_parsed_as s(:if,
                              s(:dregx, "", s(:evstr, s(:call, nil, :bar))),
                              nil,
                              s(:call, nil, :foo))
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

      it "works with an empty when block" do
        "case foo; when bar; end".
          must_be_parsed_as s(:case,
                              s(:call, nil, :foo),
                              s(:when, s(:array, s(:call, nil, :bar)), nil),
                              nil)
      end

      it "worrks with a splat in the when clause" do
        "case foo; when *bar; baz; end".
          must_be_parsed_as s(:case,
                              s(:call, nil, :foo),
                              s(:when,
                                s(:array,
                                  s(:splat, s(:call, nil, :bar))),
                                s(:call, nil, :baz)),
                              nil)

      end
    end
  end
end
