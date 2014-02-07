require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for block parameters" do
      specify do
        "foo do |(bar, baz)| end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args,
                                s(:masgn, :bar, :baz)))
      end

      specify do
        "foo do |(bar, *baz)| end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args,
                                s(:masgn, :bar, :"*baz")))
      end

      specify do
        "foo do |bar,*| end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar, :"*"))
      end

      specify do
        "foo do |bar, &baz| end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar, :"&baz"))
      end

      it "handles empty parameter specs" do
        "foo do ||; bar; end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:call, nil, :bar))
      end

      it "ignores a trailing comma in the block parameters" do
        "foo do |bar, | end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar))
      end
    end

    describe "for rescue/else" do
      it "works for a block with multiple rescue statements" do
        "begin foo; rescue; bar; rescue; baz; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :bar)),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :baz)))
      end

      it "works for a block with rescue and else" do
        "begin; foo; rescue; bar; else; baz; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :bar)),
                              s(:call, nil, :baz))
      end

      it "works for a block with only else" do
        "begin; foo; else; bar; end".
          must_be_parsed_as s(:block,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end
    end

    describe "for the rescue statement" do
      it "works with assignment to an error variable" do
        "begin; foo; rescue => bar; baz; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array,
                                  s(:lasgn, :bar, s(:gvar, :$!))),
                                s(:call, nil, :baz)))
      end

      it "works with assignment of the exception to an instance variable" do
        "begin; foo; rescue => @bar; baz; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array,
                                  s(:iasgn, :@bar, s(:gvar, :$!))),
                                s(:call, nil, :baz)))
      end

      it "works with empty main and rescue bodies" do
        "begin; rescue; end".
          must_be_parsed_as s(:rescue,
                              s(:resbody, s(:array), nil))
      end

      it "works with single statement main and rescue bodies" do
        "begin; foo; rescue; bar; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :bar)))
      end

      it "works with multi-statement main and rescue bodies" do
        "begin; foo; bar; rescue; baz; qux; end".
          must_be_parsed_as s(:rescue,
                              s(:block,
                                s(:call, nil, :foo),
                                s(:call, nil, :bar)),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :baz),
                                s(:call, nil, :qux)))
      end

      it "works with assignment to an error variable" do
        "begin; foo; rescue => e; bar; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array, s(:lasgn, :e, s(:gvar, :$!))),
                                s(:call, nil, :bar)))
      end

      it "works with filtering of the exception type" do
        "begin; foo; rescue Bar; baz; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array, s(:const, :Bar)),
                                s(:call, nil, :baz)))
      end

      it "works with filtering of the exception type and assignment to an error variable" do
        "begin; foo; rescue Bar => e; baz; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array,
                                  s(:const, :Bar),
                                  s(:lasgn, :e, s(:gvar, :$!))),
                                s(:call, nil, :baz)))
      end

      it "works rescuing multiple exception types" do
        "begin; foo; rescue Bar, Baz; qux; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array, s(:const, :Bar), s(:const, :Baz)),
                                s(:call, nil, :qux)))
      end

      it "works in the postfix case" do
        "foo rescue bar".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :bar)))
      end

      it "works in a plain method body" do
        "def foo; bar; rescue; baz; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args),
                              s(:rescue,
                                s(:call, nil, :bar),
                                s(:resbody,
                                  s(:array),
                                  s(:call, nil, :baz))))
      end

      it "works in a method body inside begin..end" do
        "def foo; bar; begin; baz; rescue; qux; end; quuz; end".
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args),
                              s(:call, nil, :bar),
                              s(:rescue,
                                s(:call, nil, :baz),
                                s(:resbody, s(:array), s(:call, nil, :qux))),
                              s(:call, nil, :quuz))
      end
    end

    describe "for the ensure statement" do
      it "works with single statement main and ensure bodies" do
        "begin; foo; ensure; bar; end".
          must_be_parsed_as s(:ensure,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it "works with multi-statement main and ensure bodies" do
        "begin; foo; bar; ensure; baz; qux; end".
          must_be_parsed_as s(:ensure,
                              s(:block,
                                s(:call, nil, :foo),
                                s(:call, nil, :bar)),
                              s(:block,
                                s(:call, nil, :baz),
                                s(:call, nil, :qux)))
      end

      it "works together with rescue" do
        "begin; foo; rescue; bar; ensure; baz; end".
          must_be_parsed_as s(:ensure,
                              s(:rescue,
                                s(:call, nil, :foo),
                                s(:resbody,
                                  s(:array),
                                  s(:call, nil, :bar))),
                              s(:call, nil, :baz))
      end

      it "works with empty main and ensure bodies" do
        "begin; ensure; end".
          must_be_parsed_as s(:ensure, s(:nil))
      end
    end

    describe "for lists of consecutive statments" do
      it "removes extra blocks for grouped statements at the start of the list" do
        "(foo; bar); baz".
          must_be_parsed_as s(:block,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar),
                              s(:call, nil, :baz))
      end

      it "keeps extra blocks for grouped statements at the end of the list" do
        "foo; (bar; baz)".
          must_be_parsed_as s(:block,
                              s(:call, nil, :foo),
                              s(:block,
                                s(:call, nil, :bar),
                                s(:call, nil, :baz)))
      end
    end

    describe "for stabby lambda" do
      it "works in the simple case" do
        "->(foo) { bar }".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :lambda),
                              s(:args, :foo),
                              s(:call, nil, :bar)) 
      end

      it "works when there are no arguments" do
        "-> { bar }".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :lambda),
                              0,
                              s(:call, nil, :bar)) 
      end
    end
  end
end
