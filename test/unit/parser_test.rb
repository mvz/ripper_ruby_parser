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
      sexp_p.expect :filename=, nil, ['(string)']
      sexp_p.expect :extra_compatible=, nil, [false]

      parser = RipperRubyParser::Parser.new sexp_p
      result = parser.parse "any code"

      result.must_equal s(:result)
      sexp_p.verify
    end

    describe "for a class declaration" do
      it "works with a namespaced class name" do
        result = parser.parse "class Foo::Bar; end"
        result.must_equal s(:class,
                            s(:colon2, s(:const, :Foo), :Bar),
                            nil,
                            s(:scope))
      end
    end

    describe "for a module declaration" do
      it "works with a namespaced module name" do
        result = parser.parse "module Foo::Bar; end"
        result.must_equal s(:module,
                            s(:colon2, s(:const, :Foo), :Bar),
                            s(:scope))
      end
    end

    describe "for if" do
      it "works in the postfix case" do
        result = parser.parse "foo if bar"
        result.must_equal s(:if,
                            s(:call, nil, :bar, s(:arglist)),
                            s(:call, nil, :foo, s(:arglist)),
                            nil)
      end

      it "works in the block case" do
        result = parser.parse "if foo; bar; end"
        result.must_equal s(:if,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)),
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

      it "works with a splat argument" do
        result = parser.parse "return *foo"
        result.must_equal s(:return,
                            s(:svalue,
                              s(:splat,
                                s(:call, nil, :foo, s(:arglist)))))
      end

      it "works with multiple arguments" do
        result = parser.parse "return foo, bar"
        result.must_equal s(:return,
                            s(:array,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:call, nil, :bar, s(:arglist))))
      end

      it "works with a regular argument and a splat argument" do
        result = parser.parse "return foo, *bar"
        result.must_equal s(:return,
                            s(:array,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:splat,
                                s(:call, nil, :bar, s(:arglist)))))
      end
    end

    describe "for the until statement" do
      it "works in the prefix block case with do" do
        result = parser.parse "until foo do; bar; end"
        result.must_equal s(:until,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)), true)
      end

      it "works in the prefix block case without do" do
        result = parser.parse "until foo; bar; end"
        result.must_equal s(:until,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)), true)
      end

      it "works in the single-line postfix case" do
        result = parser.parse "foo until bar"
        result.must_equal s(:until,
                            s(:call, nil, :bar, s(:arglist)),
                            s(:call, nil, :foo, s(:arglist)), true)
      end

      it "works in the block postfix case" do
        result = parser.parse "begin; foo; end until bar"
        result.must_equal s(:until,
                            s(:call, nil, :bar, s(:arglist)),
                            s(:call, nil, :foo, s(:arglist)), false)
      end
    end

    describe "for the while statement" do
      it "works with do" do
        result = parser.parse "while foo do; bar; end"
        result.must_equal s(:while,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)), true)
      end

      it "works without do" do
        result = parser.parse "while foo; bar; end"
        result.must_equal s(:while,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)), true)
      end
    end

    describe "for the for statement" do
      it "works with do" do
        result = suppress_warnings {
          parser.parse "for foo in bar do; baz; end" }
        result.must_equal s(:for,
                            s(:call, nil, :bar, s(:arglist)),
                            s(:lasgn, :foo),
                            s(:call, nil, :baz, s(:arglist)))
      end

      it "works without do" do
        result = suppress_warnings {
          parser.parse "for foo in bar; baz; end" }
        result.must_equal s(:for,
                            s(:call, nil, :bar, s(:arglist)),
                            s(:lasgn, :foo),
                            s(:call, nil, :baz, s(:arglist)))
      end
    end

    describe "for a begin..end block" do
      it "works with no statements" do
        result = parser.parse "begin; end"
        result.must_equal s(:nil)
      end

      it "works with one statement" do
        result = parser.parse "begin; foo; end"
        result.must_equal s(:call, nil, :foo, s(:arglist))
      end

      it "works with multiple statements" do
        result = parser.parse "begin; foo; bar; end"
        result.must_equal s(:block,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)))
      end
    end

    describe "for the rescue statement" do
      it "works with single statement main and rescue bodies" do
        result = parser.parse "begin; foo; rescue; bar; end"
        result.must_equal s(:rescue,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:resbody,
                              s(:array),
                              s(:call, nil, :bar, s(:arglist))))
      end

      it "works with multi-statement main and rescue bodies" do
        result = parser.parse "begin; foo; bar; rescue; baz; qux; end"
        result.must_equal s(:rescue,
                            s(:block,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:call, nil, :bar, s(:arglist))),
                            s(:resbody,
                              s(:array),
                              s(:block,
                                s(:call, nil, :baz, s(:arglist)),
                                s(:call, nil, :qux, s(:arglist)))))
      end

      it "works with assignment to an error variable" do
        result = suppress_warnings {
          parser.parse "begin; foo; rescue => e; bar; end" }
        result.must_equal s(:rescue,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:resbody,
                              s(:array, s(:lasgn, :e, s(:gvar, :$!))),
                              s(:call, nil, :bar, s(:arglist))))
      end

      it "works with filtering of the exception type" do
        result = parser.parse "begin; foo; rescue Bar; baz; end"
        result.must_equal s(:rescue,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:resbody,
                              s(:array, s(:const, :Bar)),
                              s(:call, nil, :baz, s(:arglist))))
      end

      it "works with filtering of the exception type and assignment to an error variable" do
        result = suppress_warnings {
          parser.parse "begin; foo; rescue Bar => e; baz; end" }
        result.must_equal s(:rescue,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:resbody,
                              s(:array,
                                s(:const, :Bar),
                                s(:lasgn, :e, s(:gvar, :$!))),
                              s(:call, nil, :baz, s(:arglist))))
      end

      it "works rescuing multiple exception types" do
        result = parser.parse "begin; foo; rescue Bar, Baz; qux; end"
        result.must_equal s(:rescue,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:resbody,
                              s(:array, s(:const, :Bar), s(:const, :Baz)),
                              s(:call, nil, :qux, s(:arglist))))
      end

      it "works in the postfix case" do
        result = parser.parse "foo rescue bar"
        result.must_equal s(:rescue,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:resbody,
                              s(:array),
                              s(:call, nil, :bar, s(:arglist))))
      end
    end

    describe "for the ensure statement" do
      it "works with single statement main and ensure bodies" do
        result = parser.parse "begin; foo; ensure; bar; end"
        result.must_equal s(:ensure,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "works with multi-statement main and ensure bodies" do
        result = parser.parse "begin; foo; bar; ensure; baz; qux; end"
        result.must_equal s(:ensure,
                            s(:block,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:call, nil, :bar, s(:arglist))),
                            s(:block,
                              s(:call, nil, :baz, s(:arglist)),
                              s(:call, nil, :qux, s(:arglist))))
      end

      it "works together with rescue" do
        result = parser.parse "begin; foo; rescue; bar; ensure; baz; end"
        result.must_equal s(:ensure,
                            s(:rescue,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :bar, s(:arglist)))),
                            s(:call, nil, :baz, s(:arglist)))
      end
    end

    describe "for the undef statement" do
      it "works with a single bareword identifier" do
        result = parser.parse "undef foo"
        result.must_equal s(:undef, s(:lit, :foo))
      end

      it "works with a single symbol" do
        result = parser.parse "undef :foo"
        result.must_equal s(:undef, s(:lit, :foo))
      end

      it "works with multiple bareword identifiers" do
        result = parser.parse "undef foo, bar"
        result.must_equal s(:block,
                            s(:undef, s(:lit, :foo)),
                            s(:undef, s(:lit, :bar)))
      end

      it "works with multiple bareword symbols" do
        result = parser.parse "undef :foo, :bar"
        result.must_equal s(:block,
                            s(:undef, s(:lit, :foo)),
                            s(:undef, s(:lit, :bar)))
      end
    end

    describe "for the alias statement" do
      it "works with regular barewords" do
        result = parser.parse "alias foo bar"
        result.must_equal s(:alias,
                            s(:lit, :foo), s(:lit, :bar))
      end

      it "works with symbols" do
        result = parser.parse "alias :foo :bar"
        result.must_equal s(:alias,
                            s(:lit, :foo), s(:lit, :bar))
      end

      it "works with operator barewords" do
        result = parser.parse "alias + -"
        result.must_equal s(:alias,
                            s(:lit, :+), s(:lit, :-))
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

      it "works for a simple case passing a block" do
        result = parser.parse "foo &bar"
        result.must_equal s(:call, nil, :foo,
                            s(:arglist,
                              s(:block_pass,
                                s(:call, nil, :bar, s(:arglist)))))
      end

      it "works for a bare hash" do
        result = parser.parse "foo bar => baz"
        result.must_equal s(:call, nil, :foo,
                            s(:arglist,
                              s(:hash,
                                s(:call, nil, :bar, s(:arglist)),
                                s(:call, nil, :baz, s(:arglist)))))
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

      it "works for an array created with %W" do
        result = parser.parse "%W(foo bar)"
        result.must_equal s(:array, s(:str, "foo"), s(:str, "bar"))
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

      it "works for a hash with label keys (Ruby 1.9 only)" do
        result = parser.parse "{foo: bar, baz: qux}"
        result.must_equal s(:hash,
                            s(:lit, :foo),
                            s(:call, nil, :bar, s(:arglist)),
                            s(:lit, :baz),
                            s(:call, nil, :qux, s(:arglist)))
      end
    end

    describe "for number literals" do
      it "works for floats" do
        result = parser.parse "3.14"
        result.must_equal s(:lit, 3.14)
      end

      it "works for octal integer literals" do
        result = parser.parse "0700"
        result.must_equal s(:lit, 448)
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
      it "works with def with receiver" do
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

      it "works with a simple splat" do
        result = parser.parse "def foo *bar; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args, :"*bar"),
                            s(:scope, s(:block, s(:nil))))
      end

      it "works with a regular argument plus splat" do
        result = parser.parse "def foo bar, *baz; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args, :bar, :"*baz"),
                            s(:scope, s(:block, s(:nil))))
      end

      it "works with a nameless splat" do
        result = parser.parse "def foo *; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args, :"*"),
                            s(:scope, s(:block, s(:nil))))
      end

      it "works for a simple case with explicit block parameter" do
        result = parser.parse "def foo &bar; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args, :"&bar"),
                            s(:scope, s(:block, s(:nil))))
      end

      it "works with a regular argument plus explicit block parameter" do
        result = parser.parse "def foo bar, &baz; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args, :bar, :"&baz"),
                            s(:scope, s(:block, s(:nil))))
      end

      it "works with a argument with default value plus explicit block parameter" do
        result = parser.parse "def foo bar=1, &baz; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args,
                              :bar, :"&baz",
                              s(:block,
                                s(:lasgn, :bar, s(:lit, 1)))),
                            s(:scope, s(:block, s(:nil))))
      end

      it "works with a splat plus explicit block parameter" do
        result = parser.parse "def foo *bar, &baz; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args, :"*bar", :"&baz"),
                            s(:scope, s(:block, s(:nil))))
      end

      it "works with an argument with default value plus splat" do
        result = parser.parse "def foo bar=1, *baz; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args, :bar, :"*baz",
                              s(:block,
                                s(:lasgn, :bar, s(:lit, 1)))),
                            s(:scope, s(:block, s(:nil))))
      end

      it "works when the method name is an operator" do
        result = parser.parse "def +; end"
        result.must_equal s(:defn, :+, s(:args),
                            s(:scope, s(:block, s(:nil))))
      end
    end

    describe "for method calls" do
      describe "without a receiver" do
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

        it "works with an empty parameter list and no brackets" do
          result = parser.parse "foo"
          result.must_equal s(:call, nil, :foo, s(:arglist))
        end

        it "works with brackets around an empty parameter list" do
          result = parser.parse "foo()"
          result.must_equal s(:call, nil, :foo, s(:arglist))
        end

        it "works for methods ending in a question mark" do
          result = parser.parse "foo?"
          result.must_equal s(:call, nil, :foo?, s(:arglist))
        end

        it "works with nested calls without brackets" do
          result = parser.parse "foo bar baz"
          result.must_equal s(:call, nil, :foo,
                              s(:arglist,
                                s(:call, nil, :bar,
                                  s(:arglist,
                                    s(:call, nil, :baz, s(:arglist))))))
        end
      end

      describe "with a receiver" do
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

        it "works with nested calls without brackets" do
          result = parser.parse "foo.bar baz qux"
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

    describe "for blocks" do
      it "works with next with no arguments" do
        result = parser.parse "foo do; next; end"
        result.must_equal s(:iter,
                            s(:call, nil, :foo, s(:arglist)),
                            nil,
                            s(:next))
      end

      it "works with next with one argument" do
        result = parser.parse "foo do; next bar; end"
        result.must_equal s(:iter,
                            s(:call, nil, :foo, s(:arglist)),
                            nil,
                            s(:next, s(:call, nil, :bar, s(:arglist))))
      end

      it "works with next with several arguments" do
        result = parser.parse "foo do; next bar, baz; end"
        result.must_equal s(:iter,
                            s(:call, nil, :foo, s(:arglist)),
                            nil,
                            s(:next,
                              s(:array,
                                s(:call, nil, :bar, s(:arglist)),
                                s(:call, nil, :baz, s(:arglist)))))
      end

      it "works with break with no arguments" do
        result = parser.parse "foo do; break; end"
        result.must_equal s(:iter,
                            s(:call, nil, :foo, s(:arglist)),
                            nil,
                            s(:break))
      end

      it "works with break with one argument" do
        result = parser.parse "foo do; break bar; end"
        result.must_equal s(:iter,
                            s(:call, nil, :foo, s(:arglist)),
                            nil,
                            s(:break, s(:call, nil, :bar, s(:arglist))))
      end

      it "works with break with several arguments" do
        result = parser.parse "foo do; break bar, baz; end"
        result.must_equal s(:iter,
                            s(:call, nil, :foo, s(:arglist)),
                            nil,
                            s(:break,
                              s(:array,
                                s(:call, nil, :bar, s(:arglist)),
                                s(:call, nil, :baz, s(:arglist)))))
      end

      it "works with redo" do
        result = parser.parse "foo do; redo; end"
        result.must_equal s(:iter,
                            s(:call, nil, :foo, s(:arglist)),
                            nil,
                            s(:redo))
      end
    end

    describe "for yield" do
      it "works with no arguments and no brackets" do
        result = parser.parse "yield"
        result.must_equal s(:yield)
      end

      it "works with brackets but no arguments" do
        result = parser.parse "yield()"
        result.must_equal s(:yield)
      end

      it "works with one argument and no brackets" do
        result = parser.parse "yield foo"
        result.must_equal s(:yield, s(:call, nil, :foo, s(:arglist)))
      end

      it "works with one argument and brackets" do
        result = parser.parse "yield(foo)"
        result.must_equal s(:yield, s(:call, nil, :foo, s(:arglist)))
      end

      it "works with multiple arguments and no brackets" do
        result = parser.parse "yield foo, bar"
        result.must_equal s(:yield,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "works with multiple arguments and brackets" do
        result = parser.parse "yield(foo, bar)"
        result.must_equal s(:yield,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "works with splat" do
        result = parser.parse "yield foo, *bar"
        result.must_equal s(:yield,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:splat, s(:call, nil, :bar, s(:arglist))))
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
        result = parser.parse '/\\)/'
        result.must_equal s(:lit, /\)/)
      end

      it "works for regex literals with escape sequences" do
        result = parser.parse '/\\)\\n\\\\/'
        result.must_equal s(:lit, /\)\n\\/)
      end

      it "works for regexes with interpolations" do
        result = parser.parse '/foo#{bar}baz/'
        result.must_equal s(:dregx,
                            "foo",
                            s(:evstr, s(:call, nil, :bar, s(:arglist))),
                            s(:str, "baz"))
      end

      it "works for a regex literal with the multiline flag" do
        result = parser.parse "/foo/m"
        result.must_equal s(:lit, /foo/m)
      end

      it "works for a regex literal with the extended flag" do
        result = parser.parse "/foo/x"
        result.must_equal s(:lit, /foo/x)
      end

      it "works for a regex literal with the ignorecase flag" do
        result = parser.parse "/foo/i"
        result.must_equal s(:lit, /foo/i)
      end

      it "works for a regex literal with a combination of flags" do
        result = parser.parse "/foo/ixm"
        result.must_equal s(:lit, /foo/ixm)
      end

      it "works for a regex literal with flags and interpolation" do
        result = parser.parse '/foo#{bar}/ixm'
        result.must_equal s(:dregx,
                            "foo",
                            s(:evstr, s(:call, nil, :bar, s(:arglist))),
                            7)
      end

      it "works for a regex literal with interpolate-once flag" do
        result = parser.parse '/foo#{bar}/o'
        result.must_equal s(:dregx_once,
                            "foo",
                            s(:evstr, s(:call, nil, :bar, s(:arglist))))
      end

      it "works for simple dsyms" do
        result = parser.parse ':"foo"'
        result.must_equal s(:lit, :foo)
      end

      it "works for dsyms with interpolations" do
        result = parser.parse ':"foo#{bar}"'
        result.must_equal s(:dsym,
                            "foo",
                            s(:evstr, s(:call, nil, :bar, s(:arglist))))
      end

      it "works for character literals (which are string literals in Ruby 1.9.3)" do
        result = parser.parse "?a"
        result.must_equal s(:lit, "a")
      end

      it "works for character literals in extra compatible mode" do
        parser.extra_compatible = true
        result = parser.parse "?a"
        result.must_equal s(:lit, 97)
      end

      it "works for basic backtick strings" do
        result = parser.parse '`foo`'
        result.must_equal s(:xstr, "foo")
      end

      it "works for interpolated backtick strings" do
        result = parser.parse '`foo#{bar}`'
        result.must_equal s(:dxstr,
                            "foo",
                            s(:evstr, s(:call, nil, :bar, s(:arglist))))
      end

      it "works for backtick strings with escape sequences" do
        result = parser.parse '`foo\\n`'
        result.must_equal s(:xstr, "foo\n")
      end

    end

    describe "for the __FILE__ keyword" do
      describe "when not passing a file name" do
        it "creates a string sexp with value '(string)'" do
          result = parser.parse "__FILE__"
          result.must_equal s(:str, "(string)")
        end
      end

      describe "when passing a file name" do
        it "creates a string sexp with the file name" do
          result = parser.parse "__FILE__", "foo"
          result.must_equal s(:str, "foo")
        end
      end
    end

    describe "for the __LINE__ keyword" do
      it "creates a literal sexp with value of the line number" do
        result = parser.parse "__LINE__"
        result.must_equal s(:lit, 1)
        result = parser.parse "\n__LINE__"
        result.must_equal s(:lit, 2)
      end
    end

    describe "for constant references" do
      it "works when explicitely starting from the root namespace" do
        result = parser.parse "::Foo"
        result.must_equal s(:colon3, :Foo)
      end

      it "works with a three-level constant lookup" do
        result = parser.parse "Foo::Bar::Baz"
        result.must_equal s(:colon2,
                            s(:colon2, s(:const, :Foo), :Bar),
                            :Baz)
      end
    end

    describe "for variable references" do
      it "works for self" do
        result = parser.parse "self"
        result.must_equal s(:self)
      end

      it "works for instance variables" do
        result = parser.parse "@foo"
        result.must_equal s(:ivar, :@foo)
      end

      it "works for global variables" do
        result = parser.parse "$foo"
        result.must_equal s(:gvar, :$foo)
      end

      it "works for regexp match references" do
        result = parser.parse "$1"
        result.must_equal s(:nth_ref, 1)
      end

      it "works for class variables" do
        result = parser.parse "@@foo"
        result.must_equal s(:cvar, :@@foo)
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

      it "works when assigning to an attribute" do
        result = parser.parse "foo.bar = baz"
        result.must_equal s(:attrasgn,
                            s(:call, nil, :foo, s(:arglist)),
                            :bar=,
                            s(:arglist, s(:call, nil, :baz, s(:arglist))))
      end

      it "works when assigning to a class variable" do
        result = parser.parse "@@foo = bar"
        result.must_equal s(:cvdecl,
                            :@@foo,
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "works when assigning to a class variable inside a method" do
        result = parser.parse "def foo; @@bar = baz; end"
        result.must_equal s(:defn,
                            :foo, s(:args),
                            s(:scope,
                              s(:block,
                                s(:cvasgn, :@@bar, s(:call, nil, :baz, s(:arglist))))))
      end

      it "works when assigning to a class variable inside a method with a receiver" do
        result = parser.parse "def self.foo; @@bar = baz; end"
        result.must_equal s(:defs,
                            s(:self),
                            :foo, s(:args),
                            s(:scope,
                              s(:block,
                                s(:cvasgn, :@@bar, s(:call, nil, :baz, s(:arglist))))))
      end

      it "works when assigning to a global variable" do
        result = parser.parse "$foo = bar"
        result.must_equal s(:gasgn,
                            :$foo,
                            s(:call, nil, :bar, s(:arglist)))
      end
    end

    describe "for operator assignment" do
      it "works with +=" do
        result = suppress_warnings { parser.parse "foo += bar" }
        result.must_equal s(:lasgn,
                            :foo,
                            s(:call,
                              s(:lvar, :foo),
                              :+,
                              s(:arglist, s(:call, nil, :bar, s(:arglist)))))
      end

      it "works with -=" do
        result = suppress_warnings { parser.parse "foo -= bar" }
        result.must_equal s(:lasgn,
                            :foo,
                            s(:call,
                              s(:lvar, :foo),
                              :-,
                              s(:arglist, s(:call, nil, :bar, s(:arglist)))))
      end

      it "works with ||=" do
        result = suppress_warnings { parser.parse "foo ||= bar" }
        result.must_equal s(:op_asgn_or,
                            s(:lvar, :foo),
                            s(:lasgn, :foo,
                              s(:call, nil, :bar, s(:arglist))))
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

      it "works with ||= when assigning to a collection element" do
        result = parser.parse "foo[bar] ||= baz"
        result.must_equal s(:op_asgn1,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:arglist, s(:call, nil, :bar, s(:arglist))),
                            :"||",
                            s(:call, nil, :baz, s(:arglist)))
      end

      it "works when assigning to an attribute" do
        result = parser.parse "foo.bar += baz"
        result.must_equal s(:op_asgn2,
                            s(:call, nil, :foo, s(:arglist)),
                            :bar=,
                            :+,
                            s(:call, nil, :baz, s(:arglist)))
      end

      it "works with ||= when assigning to an attribute" do
        result = parser.parse "foo.bar ||= baz"
        result.must_equal s(:op_asgn2,
                            s(:call, nil, :foo, s(:arglist)),
                            :bar=,
                            :"||",
                            s(:call, nil, :baz, s(:arglist)))
      end
    end

    describe "for multiple assignment" do
      it "works the same number of items on each side" do
        result = suppress_warnings { parser.parse "foo, bar = baz, qux" }
        result.must_equal s(:masgn,
                            s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                            s(:array,
                              s(:call, nil, :baz, s(:arglist)),
                              s(:call, nil, :qux, s(:arglist))))
      end

      it "works with a single item on the right-hand side" do
        result = suppress_warnings { parser.parse "foo, bar = baz" }
        result.must_equal s(:masgn,
                            s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                            s(:to_ary,
                              s(:call, nil, :baz, s(:arglist))))
      end

      it "works with left-hand splat" do
        result = suppress_warnings { parser.parse "foo, *bar = baz, qux" }
        result.must_equal s(:masgn,
                            s(:array, s(:lasgn, :foo), s(:splat, s(:lasgn, :bar))),
                            s(:array,
                              s(:call, nil, :baz, s(:arglist)),
                              s(:call, nil, :qux, s(:arglist))))
      end

      it "works with brackets around the left-hand side" do
        result = suppress_warnings { parser.parse "(foo, bar) = baz" }
        result.must_equal s(:masgn,
                            s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                            s(:to_ary,
                              s(:call, nil, :baz, s(:arglist))))
      end

      it "works with complex destructuring" do
        result = suppress_warnings { parser.parse "foo, (bar, baz) = qux" }
        result.must_equal s(:masgn,
                            s(:array,
                              s(:lasgn, :foo),
                              s(:masgn,
                                s(:array,
                                  s(:lasgn, :bar),
                                  s(:lasgn, :baz)))),
                            s(:to_ary,
                              s(:call, nil, :qux, s(:arglist))))
      end

      it "works with instance variables" do
        result = parser.parse "@foo, @bar = baz"
        result.must_equal s(:masgn,
                            s(:array, s(:iasgn, :@foo), s(:iasgn, :@bar)),
                            s(:to_ary,
                              s(:call, nil, :baz, s(:arglist))))
      end

      it "works with class variables" do
        result = parser.parse "@@foo, @@bar = baz"
        result.must_equal s(:masgn,
                            s(:array, s(:cvdecl, :@@foo), s(:cvdecl, :@@bar)),
                            s(:to_ary,
                              s(:call, nil, :baz, s(:arglist))))
      end

      it "works with attributes" do
        result = parser.parse "foo.bar, foo.baz = qux"
        result.must_equal s(:masgn,
                            s(:array,
                              s(:attrasgn,
                                s(:call, nil, :foo, s(:arglist)),
                                :bar=,
                                s(:arglist)),
                              s(:attrasgn,
                                s(:call, nil, :foo, s(:arglist)),
                                :baz=,
                                s(:arglist))),
                            s(:to_ary,
                              s(:call, nil, :qux, s(:arglist))))
      end

      it "works with collection elements" do
        result = parser.parse "foo[1], bar[2] = baz"
        result.must_equal s(:masgn,
                            s(:array,
                              s(:attrasgn,
                                s(:call, nil, :foo, s(:arglist)),
                                :[]=,
                                s(:arglist, s(:lit, 1))),
                              s(:attrasgn,
                                s(:call, nil, :bar, s(:arglist)),
                                :[]=,
                                s(:arglist, s(:lit, 2)))),
                            s(:to_ary, s(:call, nil, :baz, s(:arglist))))
      end

      it "works with constants" do
        result = parser.parse "Foo, Bar = baz"
        result.must_equal s(:masgn,
                            s(:array, s(:cdecl, :Foo), s(:cdecl, :Bar)),
                            s(:to_ary,
                              s(:call, nil, :baz, s(:arglist))))
      end

      it "works with instance variables and splat" do
        result = parser.parse "@foo, *@bar = baz"
        result.must_equal s(:masgn,
                            s(:array,
                              s(:iasgn, :@foo),
                              s(:splat, s(:iasgn, :@bar))),
                            s(:to_ary,
                              s(:call, nil, :baz, s(:arglist))))
      end

    end

    describe "for operators" do
      it "handles :and" do
        result = parser.parse "foo and bar"
        result.must_equal s(:and,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "handles double :and" do
        result = parser.parse "foo and bar and baz"
        result.must_equal s(:and,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:and,
                              s(:call, nil, :bar, s(:arglist)),
                              s(:call, nil, :baz, s(:arglist))))
      end

      it "handles :or" do
        result = parser.parse "foo or bar"
        result.must_equal s(:or,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "handles double :or" do
        result = parser.parse "foo or bar or baz"
        result.must_equal s(:or,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:or,
                              s(:call, nil, :bar, s(:arglist)),
                              s(:call, nil, :baz, s(:arglist))))
      end

      it "handles :or after :and" do
        result = parser.parse "foo and bar or baz"
        result.must_equal s(:or,
                            s(:and,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:call, nil, :bar, s(:arglist))),
                            s(:call, nil, :baz, s(:arglist)))
      end

      it "handles :and after :or" do
        result = parser.parse "foo or bar and baz"
        result.must_equal s(:and,
                            s(:or,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:call, nil, :bar, s(:arglist))),
                            s(:call, nil, :baz, s(:arglist)))
      end

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

      it "handles :!=" do
        result = parser.parse "foo != bar"
        result.must_equal s(:not,
                              s(:call,
                                s(:call, nil, :foo, s(:arglist)),
                                :==,
                                s(:arglist,
                                  s(:call, nil, :bar, s(:arglist)))))
      end

      it "handles :=~ with two non-literals" do
        result = parser.parse "foo =~ bar"
        result.must_equal s(:call,
                            s(:call, nil, :foo, s(:arglist)),
                            :=~,
                            s(:arglist, s(:call, nil, :bar, s(:arglist))))
      end

      it "handles :=~ with literal regexp on the left hand side" do
        result = parser.parse "/foo/ =~ bar"
        result.must_equal s(:match2,
                            s(:lit, /foo/),
                            s(:call, nil, :bar, s(:arglist)))
      end

      it "handles :=~ with literal regexp on the right hand side" do
        result = parser.parse "foo =~ /bar/"
        result.must_equal s(:match3,
                            s(:lit, /bar/),
                            s(:call, nil, :foo, s(:arglist)))
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

      it "handles unary plus with a number literal" do
        result = parser.parse "+ 1"
        result.must_equal s(:lit, 1)
      end

      it "handles unary plus with a non-literal" do
        result = parser.parse "+ foo"
        result.must_equal s(:call,
                            s(:call, nil, :foo, s(:arglist)),
                            :+@,
                            s(:arglist))
      end

      it "handles unary not" do
        result = parser.parse "not foo"
        result.must_equal s(:not, s(:call, nil, :foo, s(:arglist)))
      end

      it "converts :! to :not" do
        result = parser.parse "!foo"
        result.must_equal s(:not, s(:call, nil, :foo, s(:arglist)))
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

      it "handles the ternary operator" do
        result = parser.parse "foo ? bar : baz"
        result.must_equal s(:if,
                            s(:call, nil, :foo, s(:arglist)),
                            s(:call, nil, :bar, s(:arglist)),
                            s(:call, nil, :baz, s(:arglist)))
      end
    end

    describe "for expressions" do
      it "handles assignment inside binary operator expressions" do
        result = suppress_warnings { parser.parse "foo + (bar = baz)" }
        result.must_equal s(:call,
                            s(:call, nil, :foo, s(:arglist)),
                            :+,
                            s(:arglist,
                              s(:lasgn,
                                :bar,
                                s(:call, nil, :baz, s(:arglist)))))
      end

      it "handles assignment inside unary operator expressions" do
        result = suppress_warnings { parser.parse "+(foo = bar)" }
        result.must_equal s(:call,
                            s(:lasgn, :foo, s(:call, nil, :bar, s(:arglist))),
                            :+@,
                            s(:arglist))
      end
    end

    # Note: differences in the handling of comments are not caught by Sexp's
    # implementation of equality.
    describe "for comments" do
      it "handles method comments" do
        result = parser.parse "# Foo\ndef foo; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args), s(:scope, s(:block, s(:nil))))
        result.comments.must_equal "# Foo\n"
      end

      it "matches comments to the correct entity" do
        result = parser.parse "# Foo\nclass Foo\n# Bar\ndef bar\nend\nend"
        result.must_equal s(:class, :Foo, nil,
                            s(:scope,
                              s(:defn, :bar,
                                s(:args), s(:scope, s(:block, s(:nil))))))
        result.comments.must_equal "# Foo\n"
        defn = result[3][1]
        defn.sexp_type.must_equal :defn
        defn.comments.must_equal "# Bar\n"
      end

      it "combines multi-line comments" do
        result = parser.parse "# Foo\n# Bar\ndef foo; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args), s(:scope, s(:block, s(:nil))))
        result.comments.must_equal "# Foo\n# Bar\n"
      end
    end

    # Note: differences in the handling of line numbers are not caught by
    # Sexp's implementation of equality.
    describe "assigning line numbers" do
      it "works for a plain method call" do
        result = parser.parse "foo"
        result.line.must_equal 1
      end

      it "works for a method call with brackets" do
        result = parser.parse "foo()"
        result.line.must_equal 1
      end

      it "works for a method call with receiver" do
        result = parser.parse "foo.bar"
        result.line.must_equal 1
      end

      it "works for a method call with receiver and arguments" do
        result = parser.parse "foo.bar baz"
        result.line.must_equal 1
      end

      it "works for a method call with arguments" do
        result = parser.parse "foo bar"
        result.line.must_equal 1
      end

      it "works for a block with two lines" do
        result = parser.parse "foo\nbar\n"
        result.sexp_type.must_equal :block
        result[1].line.must_equal 1
        result[2].line.must_equal 2
        result.line.must_equal 1
      end

      it "works for a constant reference" do
        result = parser.parse "Foo"
        result.line.must_equal 1
      end

      it "works for an instance variable" do
        result = parser.parse "@foo"
        result.line.must_equal 1
      end

      it "works for a global variable" do
        result = parser.parse "$foo"
        result.line.must_equal 1
      end

      it "works for a class variable" do
        result = parser.parse "@@foo"
        result.line.must_equal 1
      end

      it "works for a local variable" do
        result = parser.parse "foo = bar\nfoo\n"
        result.sexp_type.must_equal :block
        result[1].line.must_equal 1
        result[2].line.must_equal 2
        result.line.must_equal 1
      end

      it "works for an integer literal" do
        result = parser.parse "42"
        result.line.must_equal 1
      end

      it "works for a float literal" do
        result = parser.parse "3.14"
        result.line.must_equal 1
      end

      it "works for a regular expression back reference" do
        result = parser.parse "$1"
        result.line.must_equal 1
      end

      it "works for self" do
        result = parser.parse "self"
        result.line.must_equal 1
      end

      it "works for __FILE__" do
        result = parser.parse "__FILE__"
        result.line.must_equal 1
      end

      it "works for nil" do
        result = parser.parse "nil"
        result.line.must_equal 1
      end

      it "works for a symbol literal" do
        result = parser.parse ":foo"
        result.line.must_equal 1
      end

      it "works for a class definition" do
        result = parser.parse "class Foo; end"
        result.line.must_equal 1
      end

      it "works for a module definition" do
        result = parser.parse "module Foo; end"
        result.line.must_equal 1
      end

      it "works for a method definition" do
        result = parser.parse "def foo; end"
        result.line.must_equal 1
      end

      it "works for assignment of the empty hash" do
        result = suppress_warnings { parser.parse "foo = {}" }
        result.line.must_equal 1
      end

      it "works for multiple assignment of empty hashes" do
        result = suppress_warnings { parser.parse "foo, bar = {}, {}" }
        result.line.must_equal 1
      end

      it "assigns line numbers to all nested sexps" do
        result = parser.parse "foo() do\nend\n"
        result.must_equal s(:iter,
                            s(:call,
                              nil, :foo, s(:arglist)), nil, s(:block))
        arglist = result[1][3]
        block = result[3]
        nums = [ arglist.line, block.line ]
        nums.must_equal [1, 1]
      end

      describe "when a line number is passed" do
        it "shifts all line numbers as appropriate" do
          result = parser.parse "foo\nbar\n", '(string)', 3
          result.must_equal s(:block,
                              s(:call, nil, :foo, s(:arglist)),
                              s(:call, nil, :bar, s(:arglist)))
          result.line.must_equal 3
          result[1].line.must_equal 3
          result[2].line.must_equal 4
        end
      end
    end
  end
end
