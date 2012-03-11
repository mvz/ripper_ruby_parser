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

    describe "for if" do
      it "works in the postfix case" do
        result = parser.parse "foo if bar"
        result.must_equal s(:if,
                            s(:call, nil, :bar, s(:arglist)),
                            s(:call, nil, :foo, s(:arglist)),
                            nil)
      end

      it "works with an else clause" do
        result = parser.parse "if foo; bar; else; baz; end"
        result.must_equal s(:if,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)),
                            s(:call, nil, :baz, s(:arglist)))
      end

      it "works with an elsif clause" do
        result = parser.parse "if foo; bar; elsif baz; qux; end"
        result.must_equal s(:if,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)),
                            s(:if,
                              s(:call, nil, :baz, s(:arglist)),
                              s(:call, nil, :qux, s(:arglist)),
                              nil))
      end
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

      it "works with an else clause" do
        result = parser.parse "unless foo; bar; else; baz; end"
        result.must_equal s(:if,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :baz, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)))
      end
    end

    describe "for a case block" do
      it "works with a single when clause" do
        result = parser.parse "case foo; when bar; baz; end"
        result.must_equal s(:case,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:when,
                              s(:array, s(:call, nil, :bar, s(:arglist))),
                              s(:call, nil, :baz, s(:arglist))),
                            nil)
      end

      it "works with multiple when clauses" do
        result = parser.parse "case foo; when bar; baz; when qux; quux; end"
        result.must_equal s(:case,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:when,
                              s(:array, s(:call, nil, :bar, s(:arglist))),
                              s(:call, nil, :baz, s(:arglist))),
                            s(:when,
                              s(:array, s(:call, nil, :qux, s(:arglist))),
                              s(:call, nil, :quux, s(:arglist))),
                            nil)
      end

      it "works with multiple statements in the when block" do
        result = parser.parse "case foo; when bar; baz; qux; end"
        result.must_equal s(:case,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:when,
                              s(:array, s(:call, nil, :bar, s(:arglist))),
                              s(:block,
                                s(:call, nil, :baz, s(:arglist)),
                                s(:call, nil, :qux, s(:arglist)))),
                            nil)
      end

      it "works with an else clause" do
        result = parser.parse "case foo; when bar; baz; else; qux; end"
        result.must_equal s(:case,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:when,
                              s(:array, s(:call, nil, :bar, s(:arglist))),
                              s(:call, nil, :baz, s(:arglist))),
                            s(:call, nil, :qux, s(:arglist)))
      end
    end

    describe "for the return statement" do
      it "works with no arguments" do
        result = parser.parse "return"
        result.must_equal s(:return)
      end

      it "works with one argument" do
        result = parser.parse "return foo"
        result.must_equal s(:return,
                            s(:call, nil, :foo, s(:arglist)))
      end
    end

    describe "for the until statement" do
      it "works with do" do
        result = parser.parse "until foo do; bar; end"
        result.must_equal s(:until,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)), true)
      end

      it "works without do" do
        result = parser.parse "until foo; bar; end"
        result.must_equal s(:until,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)), true)
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

    describe "for array literals" do
      it "works for an empty array" do
        result = parser.parse "[]"
        result.must_equal s(:array)
      end

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

    describe "for hash literals" do
      it "works for an empty hash" do
        result = parser.parse "{}"
        result.must_equal s(:hash)
      end

      it "works for a hash with one pair" do
        result = parser.parse "{foo => bar}"
        result.must_equal s(:hash,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "works for a hash with multiple pairs" do
        result = parser.parse "{foo => bar, baz => qux}"
        result.must_equal s(:hash,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)),
                            s(:call, nil, :baz, s(:arglist)),
                            s(:call, nil, :qux, s(:arglist)))
      end
    end

    describe "for collection indexing" do
      it "works in the simple case" do
        result = parser.parse "foo[bar]"
        result.must_equal s(:call,
                            s(:call, nil, :foo, s(:arglist)),
                            :[],
                            s(:arglist, s(:call, nil, :bar, s(:arglist))))
      end
    end

    describe "for method definitions" do
      it "works with def with reciever" do
        result = parser.parse "def foo.bar; end"
        result.must_equal s(:defs,
                            s(:call, nil, :foo, s(:arglist)),
                            :bar,
                            s(:args),
                            s(:scope, s(:block)))
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

      it "works with brackets around the parameter list" do
        result = parser.parse "def foo(bar); end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args, :bar),
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

        it "works with brackets around an empty parameter list" do
          result = parser.parse "foo()"
          result.must_equal s(:call, nil, :foo, s(:arglist))
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

        it "works with brackets around a call with no brackets" do
          result = parser.parse "foo.bar(baz qux)"
          result.must_equal s(:call,
                              s(:call, nil, :foo, s(:arglist)),
                              :bar,
                              s(:arglist,
                                s(:call, nil, :baz,
                                  s(:arglist,
                                    s(:call, nil, :qux, s(:arglist))))))
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

        it "works for a do block with several statements" do
          result = parser.parse "foo.bar do baz; qux; end"
          result.must_equal s(:iter,
                              s(:call,
                                s(:call, nil, :foo, s(:arglist)),
                                :bar,
                                s(:arglist)),
                              nil,
                              s(:block,
                                s(:call, nil, :baz, s(:arglist)),
                                s(:call, nil, :qux, s(:arglist))))
        end
      end
    end

    describe "for literals" do
      it "works for symbols" do
        result = parser.parse ":foo"
        result.must_equal s(:lit, :foo)
      end

      it "works for symbols that look like instance variable names" do
        result = parser.parse ":@foo"
        result.must_equal s(:lit, :@foo)
      end

      it "works for empty strings" do
        result = parser.parse "''"
        result.must_equal s(:str, "")
      end

      it "works for strings with escape sequences" do
        result = parser.parse "\"\\n\""
        result.must_equal s(:str, "\n")
      end

      it "works for strings with escaped backslashes" do
        result = parser.parse "\"\\\\n\""
        result.must_equal s(:str, "\\n")
      end

      it "works for a double-quoted string representing a regex literal with escaped right bracket" do
        result = parser.parse "\"/\\)/\""
        result.must_equal s(:str, "/\\)/")
      end

      it "works for a single-quoted string representing a regex literal with escaped right bracket" do
        result = parser.parse "'/\\)/'"
        result.must_equal s(:str, "/\\)/")
      end

      it "works for a string containing escaped quotes" do
        result = parser.parse "\"\\\"\""
        result.must_equal s(:str, "\"")
      end

      it "works for trivial interpolated strings" do
        result = parser.parse '"#{foo}"'
        result.must_equal s(:dstr,
                            "",
                            s(:evstr,
                              s(:call, nil, :foo, s(:arglist))))
      end

      it "works for basic interpolated strings" do
        result = parser.parse '"foo#{bar}"'
        result.must_equal s(:dstr,
                            "foo",
                            s(:evstr,
                              s(:call, nil, :bar, s(:arglist))))
      end

      it "works for strings with several interpolations" do
        result = parser.parse '"foo#{bar}baz#{qux}"'
        result.must_equal s(:dstr,
                            "foo",
                            s(:evstr, s(:call, nil, :bar, s(:arglist))),
                            s(:str, "baz"),
                            s(:evstr, s(:call, nil, :qux, s(:arglist))))
      end

      it "works for strings with interpolations followed by escape sequences" do
        result = parser.parse '"#{foo}\\n"'
        result.must_equal  s(:dstr,
                             "",
                             s(:evstr, s(:call, nil, :foo, s(:arglist))),
                             s(:str, "\n"))
      end

      it "works for a simple regex literal" do
        result = parser.parse "/foo/"
        result.must_equal s(:lit, /foo/)
      end

      it "works for regex literals with escaped right bracket" do
        result = parser.parse '/\)/'
        result.must_equal s(:lit, /\)/)
      end

      it "works for symbols created by prefixing a simple string with :" do
        result = parser.parse ':"foo"'
        result.must_equal s(:lit, :foo)
      end
    end

    describe "for the __FILE__ keyword" do
      it "creates a string sexp with value '(string)'" do
        result = parser.parse "__FILE__"
        result.must_equal s(:str, "(string)")
      end
    end

    describe "for constant references" do
      it "works when explicitely starting from the root namespace" do
        result = parser.parse "::Foo"
        result.must_equal s(:colon3, :Foo)
      end
    end

    describe "for variable references" do
      it "works for global variables" do
        result = parser.parse "$foo"
        result.must_equal s(:gvar, :$foo)
      end

      it "works for regexp match references" do
        result = parser.parse "$1"
        result.must_equal s(:nth_ref, 1)
      end
    end

    describe "for single assignment" do
      it "works when assigning to an instance variable" do
        result = parser.parse "@foo = bar"
        result.must_equal s(:iasgn,
                            :@foo,
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "works when assigning to a constant" do
        result = parser.parse "FOO = bar"
        result.must_equal s(:cdecl,
                            :FOO,
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "works when assigning to a collection element" do
        result = parser.parse "foo[bar] = baz"
        result.must_equal s(:attrasgn,
                            s(:call, nil, :foo, s(:arglist)),
                            :[]=,
                            s(:arglist,
                              s(:call, nil, :bar, s(:arglist)),
                              s(:call, nil, :baz, s(:arglist))))
      end
    end

    describe "for operator assignment" do
      it "works with +=" do
        result = parser.parse "foo += bar"
        result.must_equal s(:lasgn,
                            :foo,
                            s(:call,
                              s(:lvar, :foo),
                              :+,
                              s(:arglist, s(:call, nil, :bar, s(:arglist)))))
      end

      it "works with -=" do
        result = parser.parse "foo -= bar"
        result.must_equal s(:lasgn,
                            :foo,
                            s(:call,
                              s(:lvar, :foo),
                              :-,
                              s(:arglist, s(:call, nil, :bar, s(:arglist)))))
      end

      it "works when assigning to an instance variable" do
        result = parser.parse "@foo += bar"
        result.must_equal s(:iasgn,
                            :@foo,
                            s(:call,
                              s(:ivar, :@foo),
                              :+,
                              s(:arglist, s(:call, nil, :bar, s(:arglist)))))
      end

      it "works when assigning to a collection element" do
        result = parser.parse "foo[bar] += baz"
        result.must_equal s(:op_asgn1,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:arglist, s(:call, nil, :bar, s(:arglist))),
                            :+,
                            s(:call, nil, :baz, s(:arglist)))
      end
    end

    describe "for multiple assignment" do
      it "works the same number of items on each side" do
        result = parser.parse "foo, bar = baz, qux"
        result.must_equal s(:masgn,
                            s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                            s(:array,
                              s(:call, nil, :baz, s(:arglist)),
                              s(:call, nil, :qux, s(:arglist))))
      end

      it "works with a single item on the right-hand side" do
        result = parser.parse "foo, bar = baz"
        result.must_equal s(:masgn,
                            s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                            s(:to_ary,
                              s(:call, nil, :baz, s(:arglist))))
      end

      it "works with left-hand splat" do
        result = parser.parse "foo, *bar = baz, qux"
        result.must_equal s(:masgn,
                            s(:array, s(:lasgn, :foo), s(:splat, s(:lasgn, :bar))),
                            s(:array,
                              s(:call, nil, :baz, s(:arglist)),
                              s(:call, nil, :qux, s(:arglist))))
      end
    end

    describe "for operators" do
      it "converts :&& to :and" do
        result = parser.parse "foo && bar"
        result.must_equal s(:and,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "converts :|| to :or" do
        result = parser.parse "foo || bar"
        result.must_equal s(:or,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "handles unary minus with a number literal" do
        result = parser.parse "-1"
        result.must_equal s(:lit, -1)
      end

      it "handles unary minus with a non-literal" do
        result = parser.parse "-foo"
        result.must_equal s(:call,
                            s(:call, nil, :foo, s(:arglist)),
                            :-@,
                            s(:arglist))
      end

      it "handles the range operator with positive number literals" do
        result = parser.parse "1..2"
        result.must_equal s(:lit, 1..2)
      end

      it "handles the range operator with negative number literals" do
        result = parser.parse "-1..-2"
        result.must_equal s(:lit, -1..-2)
      end

      it "handles the range operator with string literals" do
        result = parser.parse "'a'..'z'"
        result.must_equal s(:dot2,
                            s(:str, "a"),
                            s(:str, "z"))
      end

      it "handles the range operator with non-literals" do
        result = parser.parse "foo..bar"
        result.must_equal s(:dot2,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)))
      end
    end
  end
end
