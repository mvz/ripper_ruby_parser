require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe '#parse' do
    describe 'for blocks' do
      it 'works with no statements in the block body' do
        'foo do; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0)
      end

      it 'works with redo' do
        'foo do; redo; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:redo))
      end
    end

    describe 'for block parameters' do
      specify do
        'foo do |(bar, baz)| end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args,
                                s(:masgn, :bar, :baz)))
      end

      specify do
        'foo do |(bar, *baz)| end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args,
                                s(:masgn, :bar, :"*baz")))
      end

      specify do
        'foo do |bar,*| end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar, :"*"))
      end

      specify do
        'foo do |bar, &baz| end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar, :"&baz"))
      end

      it 'handles absent parameter specs' do
        'foo do; bar; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:call, nil, :bar))
      end

      it 'handles empty parameter specs' do
        'foo do ||; bar; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args),
                              s(:call, nil, :bar))
      end

      it 'ignores a trailing comma in the block parameters' do
        'foo do |bar, | end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar))
      end

      it 'works with zero arguments' do
        'foo do ||; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args))
      end

      it 'works with one argument' do
        'foo do |bar|; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar))
      end

      it 'works with multiple arguments' do
        'foo do |bar, baz|; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar, :baz))
      end

      it 'works with a single splat argument' do
        'foo do |*bar|; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :"*bar"))
      end

      it 'works with a combination of regular arguments and a splat argument' do
        'foo do |bar, *baz|; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:args, :bar, :"*baz"))
      end
    end

    describe 'for begin' do
      it 'works for an empty begin..end block' do
        'begin end'.must_be_parsed_as s(:nil)
      end

      it 'works for a simple begin..end block' do
        'begin; foo; end'.must_be_parsed_as s(:call, nil, :foo)
      end

      it 'works for begin..end block with more than one statement' do
        'begin; foo; bar; end'.
          must_be_parsed_as s(:block,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it 'keeps :begin for the argument of a unary operator' do
        '- begin; foo; end'.
          must_be_parsed_as s(:call,
                              s(:begin, s(:call, nil, :foo)),
                              :-@)
      end

      it 'keeps :begin for the first argument of a binary operator' do
        'begin; bar; end + foo'.
          must_be_parsed_as s(:call,
                              s(:begin, s(:call, nil, :bar)),
                              :+,
                              s(:call, nil, :foo))
      end

      it 'keeps :begin for the second argument of a binary operator' do
        'foo + begin; bar; end'.
          must_be_parsed_as s(:call,
                              s(:call, nil, :foo),
                              :+,
                              s(:begin, s(:call, nil, :bar)))
      end

      it 'does not keep :begin for the first argument of a boolean operator' do
        'begin; bar; end and foo'.
          must_be_parsed_as s(:and,
                              s(:call, nil, :bar),
                              s(:call, nil, :foo))
      end

      it 'keeps :begin for the second argument of a boolean operator' do
        'foo and begin; bar; end'.
          must_be_parsed_as s(:and,
                              s(:call, nil, :foo),
                              s(:begin, s(:call, nil, :bar)))
      end

      it 'does not keep :begin for the first argument of a shift operator' do
        'begin; bar; end << foo'.
          must_be_parsed_as s(:call,
                              s(:call, nil, :bar),
                              :<<,
                              s(:call, nil, :foo))
      end

      it 'does not keep :begin for the second argument of a shift operator' do
        'foo >> begin; bar; end'.
          must_be_parsed_as s(:call,
                              s(:call, nil, :foo),
                              :>>,
                              s(:call, nil, :bar))
      end

      it 'keeps :begin for the first argument of a ternary operator' do
        'begin; foo; end ? bar : baz'.
          must_be_parsed_as s(:if,
                              s(:begin, s(:call, nil, :foo)),
                              s(:call, nil, :bar),
                              s(:call, nil, :baz))
      end

      it 'keeps :begin for the second argument of a ternary operator' do
        'foo ? begin; bar; end : baz'.
          must_be_parsed_as s(:if,
                              s(:call, nil, :foo),
                              s(:begin, s(:call, nil, :bar)),
                              s(:call, nil, :baz))
      end

      it 'keeps :begin for the third argument of a ternary operator' do
        'foo ? bar : begin; baz; end'.
          must_be_parsed_as s(:if,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar),
                              s(:begin, s(:call, nil, :baz)))
      end
    end

    describe 'for rescue/else' do
      it 'works for a block with multiple rescue statements' do
        'begin foo; rescue; bar; rescue; baz; end'.
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :bar)),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :baz)))
      end

      it 'works for a block with rescue and else' do
        'begin; foo; rescue; bar; else; baz; end'.
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :bar)),
                              s(:call, nil, :baz))
      end

      it 'works for a block with only else' do
        'begin; foo; else; bar; end'.
          must_be_parsed_as s(:block,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end
    end

    describe 'for the rescue statement' do
      it 'works with assignment to an error variable' do
        'begin; foo; rescue => bar; baz; end'.
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array,
                                  s(:lasgn, :bar, s(:gvar, :$!))),
                                s(:call, nil, :baz)))
      end

      it 'works with assignment of the exception to an instance variable' do
        'begin; foo; rescue => @bar; baz; end'.
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array,
                                  s(:iasgn, :@bar, s(:gvar, :$!))),
                                s(:call, nil, :baz)))
      end

      it 'works with empty main and rescue bodies' do
        'begin; rescue; end'.
          must_be_parsed_as s(:rescue,
                              s(:resbody, s(:array), nil))
      end

      it 'works with single statement main and rescue bodies' do
        'begin; foo; rescue; bar; end'.
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :bar)))
      end

      it 'works with multi-statement main and rescue bodies' do
        'begin; foo; bar; rescue; baz; qux; end'.
          must_be_parsed_as s(:rescue,
                              s(:block,
                                s(:call, nil, :foo),
                                s(:call, nil, :bar)),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :baz),
                                s(:call, nil, :qux)))
      end

      it 'works with assignment to an error variable' do
        'begin; foo; rescue => e; bar; end'.
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array, s(:lasgn, :e, s(:gvar, :$!))),
                                s(:call, nil, :bar)))
      end

      it 'works with filtering of the exception type' do
        'begin; foo; rescue Bar; baz; end'.
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array, s(:const, :Bar)),
                                s(:call, nil, :baz)))
      end

      it 'works with filtering of the exception type and assignment to an error variable' do
        'begin; foo; rescue Bar => e; baz; end'.
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array,
                                  s(:const, :Bar),
                                  s(:lasgn, :e, s(:gvar, :$!))),
                                s(:call, nil, :baz)))
      end

      it 'works rescuing multiple exception types' do
        'begin; foo; rescue Bar, Baz; qux; end'.
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array, s(:const, :Bar), s(:const, :Baz)),
                                s(:call, nil, :qux)))
      end

      it 'works in the postfix case' do
        'foo rescue bar'.
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :bar)))
      end

      it 'works in a plain method body' do
        'def foo; bar; rescue; baz; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args),
                              s(:rescue,
                                s(:call, nil, :bar),
                                s(:resbody,
                                  s(:array),
                                  s(:call, nil, :baz))))
      end

      it 'works in a method body inside begin..end' do
        'def foo; bar; begin; baz; rescue; qux; end; quuz; end'.
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

    describe 'for the ensure statement' do
      it 'works with single statement main and ensure bodies' do
        'begin; foo; ensure; bar; end'.
          must_be_parsed_as s(:ensure,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it 'works with multi-statement main and ensure bodies' do
        'begin; foo; bar; ensure; baz; qux; end'.
          must_be_parsed_as s(:ensure,
                              s(:block,
                                s(:call, nil, :foo),
                                s(:call, nil, :bar)),
                              s(:block,
                                s(:call, nil, :baz),
                                s(:call, nil, :qux)))
      end

      it 'works together with rescue' do
        'begin; foo; rescue; bar; ensure; baz; end'.
          must_be_parsed_as s(:ensure,
                              s(:rescue,
                                s(:call, nil, :foo),
                                s(:resbody,
                                  s(:array),
                                  s(:call, nil, :bar))),
                              s(:call, nil, :baz))
      end

      it 'works with empty main and ensure bodies' do
        'begin; ensure; end'.
          must_be_parsed_as s(:ensure, s(:nil))
      end
    end

    describe 'for the next statement' do
      it 'works with no arguments' do
        'foo do; next; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:next))
      end

      it 'works with one argument' do
        'foo do; next bar; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:next, s(:call, nil, :bar)))
      end

      it 'works with a splat argument' do
        'foo do; next *bar; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:next,
                                s(:svalue,
                                  s(:splat,
                                    s(:call, nil, :bar)))))
      end

      it 'works with several arguments' do
        'foo do; next bar, baz; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:next,
                                s(:array,
                                  s(:call, nil, :bar),
                                  s(:call, nil, :baz))))
      end

      it 'works with a function call with parentheses' do
        'foo do; next foo(bar); end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:next,
                                s(:call, nil, :foo,
                                  s(:call, nil, :bar))))
      end

      it 'works with a function call without parentheses' do
        'foo do; next foo bar; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:next,
                                s(:call, nil, :foo,
                                  s(:call, nil, :bar))))
      end
    end

    describe 'for the break statement' do
      it 'works with break with no arguments' do
        'foo do; break; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:break))
      end

      it 'works with break with one argument' do
        'foo do; break bar; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:break, s(:call, nil, :bar)))
      end

      it 'works with a splat argument' do
        'foo do; break *bar; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:break,
                                s(:svalue,
                                  s(:splat,
                                    s(:call, nil, :bar)))))
      end

      it 'works with break with several arguments' do
        'foo do; break bar, baz; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:break,
                                s(:array,
                                  s(:call, nil, :bar),
                                  s(:call, nil, :baz))))
      end

      it 'works with break with a function call with parentheses' do
        'foo do; break foo(bar); end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:break,
                                s(:call, nil, :foo,
                                  s(:call, nil, :bar))))
      end

      it 'works with break with a function call without parentheses' do
        'foo do; break foo bar; end'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              0,
                              s(:break,
                                s(:call, nil, :foo,
                                  s(:call, nil, :bar))))
      end
    end

    describe 'for lists of consecutive statments' do
      it 'removes extra blocks for grouped statements at the start of the list' do
        '(foo; bar); baz'.
          must_be_parsed_as s(:block,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar),
                              s(:call, nil, :baz))
      end

      it 'keeps extra blocks for grouped statements at the end of the list' do
        'foo; (bar; baz)'.
          must_be_parsed_as s(:block,
                              s(:call, nil, :foo),
                              s(:block,
                                s(:call, nil, :bar),
                                s(:call, nil, :baz)))
      end
    end

    describe 'for stabby lambda' do
      it 'works in the simple case' do
        '->(foo) { bar }'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :lambda),
                              s(:args, :foo),
                              s(:call, nil, :bar))
      end

      it 'works when there are zero arguments' do
        '->() { bar }'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :lambda),
                              s(:args),
                              s(:call, nil, :bar))
      end

      it 'works when there are no arguments' do
        '-> { bar }'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :lambda),
                              0,
                              s(:call, nil, :bar))
      end

      it 'works when there are no statements in the body' do
        '->(foo) { }'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :lambda),
                              s(:args, :foo))
      end

      it 'works when there are several statements in the body' do
        '->(foo) { bar; baz }'.
          must_be_parsed_as s(:iter,
                              s(:call, nil, :lambda),
                              s(:args, :foo),
                              s(:block,
                                s(:call, nil, :bar),
                                s(:call, nil, :baz)))
      end
    end
  end
end
