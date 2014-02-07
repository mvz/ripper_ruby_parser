require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for regular if" do
      it "works with a single statement" do
        "if foo; bar; end".
          must_be_parsed_as s(:if,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar),
                              nil)
      end

      it "works with multiple statements" do
        "if foo; bar; baz; end".
          must_be_parsed_as s(:if,
                              s(:call, nil, :foo),
                              s(:block,
                                s(:call, nil, :bar),
                                s(:call, nil, :baz)),
                              nil)
      end

      it "works with an else clause" do
        "if foo; bar; else; baz; end".
          must_be_parsed_as s(:if,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar),
                              s(:call, nil, :baz))
      end

      it "works with an elsif clause" do
        "if foo; bar; elsif baz; qux; end".
          must_be_parsed_as s(:if,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar),
                              s(:if,
                                s(:call, nil, :baz),
                                s(:call, nil, :qux),
                                nil))
      end

      it "handles a negative condition correctly" do
        "if not foo; bar; end".
          must_be_parsed_as s(:if,
                              s(:call, s(:call, nil, :foo), :!),
                              s(:call, nil, :bar),
                              nil)
      end

      it "handles a negative condition in elsif correctly" do
        "if foo; bar; elsif not baz; qux; end".
          must_be_parsed_as s(:if,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar),
                              s(:if,
                                s(:call, s(:call, nil, :baz), :!),
                                s(:call, nil, :qux), nil))
      end

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

      it "handles block conditions" do
        "if (foo; bar); baz; end".
          must_be_parsed_as s(:if,
                              s(:block, s(:call, nil, :foo), s(:call, nil, :bar)),
                              s(:call, nil, :baz),
                              nil)
      end

      it "converts :dot2 to :flip2" do
        "if foo..bar; baz; end".
          must_be_parsed_as s(:if,
                              s(:flip2, s(:call, nil, :foo), s(:call, nil, :bar)),
                              s(:call, nil, :baz),
                              nil)
      end

      it "converts :dot3 to :flip3" do
        "if foo...bar; baz; end".
          must_be_parsed_as s(:if,
                              s(:flip3, s(:call, nil, :foo), s(:call, nil, :bar)),
                              s(:call, nil, :baz),
                              nil)
      end
    end

    describe "for postfix if" do
      it "works with a simple condition" do
        "foo if bar".
          must_be_parsed_as s(:if,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo),
                              nil)
      end

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
      it "works with a single statement" do
        "unless bar; foo; end".
          must_be_parsed_as s(:if,
                              s(:call, nil, :bar),
                              nil,
                              s(:call, nil, :foo))
      end

      it "works with an else clause" do
        "unless foo; bar; else; baz; end".
          must_be_parsed_as s(:if,
                              s(:call, nil, :foo),
                              s(:call, nil, :baz),
                              s(:call, nil, :bar))
      end
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
      it "works with a simple condition" do
        "foo unless bar".
          must_be_parsed_as s(:if,
                              s(:call, nil, :bar),
                              nil,
                              s(:call, nil, :foo))
      end

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

      it "works with an empty else block" do
        "case foo; when bar; baz; else; end".
          must_be_parsed_as s(:case,
                              s(:call, nil, :foo),
                              s(:when,
                                s(:array, s(:call, nil, :bar)),
                                s(:call, nil, :baz)),
                              nil)
      end

      it "works with a splat in the when clause" do
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
