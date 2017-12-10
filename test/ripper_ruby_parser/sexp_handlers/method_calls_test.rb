require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe '#parse' do
    describe 'for method calls' do
      describe 'without a receiver' do
        it 'works without parentheses' do
          'foo bar'.
            must_be_parsed_as s(:call, nil, :foo,
                                s(:call, nil, :bar))
        end

        it 'works with parentheses' do
          'foo(bar)'.
            must_be_parsed_as s(:call, nil, :foo,
                                s(:call, nil, :bar))
        end

        it 'works with an empty parameter list and no parentheses' do
          'foo'.
            must_be_parsed_as s(:call, nil, :foo)
        end

        it 'works with parentheses around an empty parameter list' do
          'foo()'.
            must_be_parsed_as s(:call, nil, :foo)
        end

        it 'works for methods ending in a question mark' do
          'foo?'.
            must_be_parsed_as s(:call, nil, :foo?)
        end

        it 'works with nested calls without parentheses' do
          'foo bar baz'.
            must_be_parsed_as s(:call, nil, :foo,
                                s(:call, nil, :bar,
                                  s(:call, nil, :baz)))
        end

        it 'works with a non-final splat argument' do
          'foo(bar, *baz, qux)'.
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:splat, s(:call, nil, :baz)),
                                s(:call, nil, :qux))
        end

        it 'works with a splat argument followed by several regular arguments' do
          'foo(bar, *baz, qux, quuz)'.
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:splat, s(:call, nil, :baz)),
                                s(:call, nil, :qux),
                                s(:call, nil, :quuz))
        end

        it 'works with a named argument' do
          'foo(bar, baz: qux)'.
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:hash, s(:lit, :baz), s(:call, nil, :qux)))
        end

        it 'works with several named arguments' do
          'foo(bar, baz: qux, quux: quuz)'.
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:hash,
                                  s(:lit, :baz), s(:call, nil, :qux),
                                  s(:lit, :quux), s(:call, nil, :quuz)))
        end

        it 'works with a double splat argument' do
          'foo(bar, **baz)'.
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:hash,
                                  s(:kwsplat, s(:call, nil, :baz))))
        end

        it 'works with a named argument followed by a double splat argument' do
          'foo(bar, baz: qux, **quuz)'.
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:hash,
                                  s(:lit, :baz), s(:call, nil, :qux),
                                  s(:kwsplat, s(:call, nil, :quuz))))
        end
      end

      describe 'with a receiver' do
        it 'works without parentheses' do
          'foo.bar baz'.
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz))
        end

        it 'works with parentheses' do
          'foo.bar(baz)'.
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz))
        end

        it 'works with parentheses around a call with no parentheses' do
          'foo.bar(baz qux)'.
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz,
                                  s(:call, nil, :qux)))
        end

        it 'works with nested calls without parentheses' do
          'foo.bar baz qux'.
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz,
                                  s(:call, nil, :qux)))
        end
      end

      describe 'safe call' do
        before do
          skip 'This is not valid syntax below Ruby 2.3' if RUBY_VERSION < '2.3.0'
        end

        it 'works without arguments' do
          'foo&.bar'.must_be_parsed_as s(:safe_call, s(:call, nil, :foo), :bar)
        end

        it 'works with arguments' do
          'foo&.bar baz'.
            must_be_parsed_as s(:safe_call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz))
        end
      end

      describe 'with blocks' do
        it 'works for a do block' do
          'foo.bar do baz; end'.
            must_be_parsed_as s(:iter,
                                s(:call,
                                  s(:call, nil, :foo),
                                  :bar),
                                0,
                                s(:call, nil, :baz))
        end

        it 'works for a do block with several statements' do
          'foo.bar do baz; qux; end'.
            must_be_parsed_as s(:iter,
                                s(:call,
                                  s(:call, nil, :foo),
                                  :bar),
                                0,
                                s(:block,
                                  s(:call, nil, :baz),
                                  s(:call, nil, :qux)))
        end
      end
    end

    describe 'for calls to super' do
      specify { 'super'.must_be_parsed_as s(:zsuper) }
      specify do
        'super foo'.must_be_parsed_as s(:super,
                                        s(:call, nil, :foo))
      end
      specify do
        'super foo, bar'.must_be_parsed_as s(:super,
                                             s(:call, nil, :foo),
                                             s(:call, nil, :bar))
      end
      specify do
        'super foo, *bar'.must_be_parsed_as s(:super,
                                              s(:call, nil, :foo),
                                              s(:splat,
                                                s(:call, nil, :bar)))
      end
      specify do
        'super foo, *bar, &baz'.
          must_be_parsed_as s(:super,
                              s(:call, nil, :foo),
                              s(:splat, s(:call, nil, :bar)),
                              s(:block_pass, s(:call, nil, :baz)))
      end
    end

    it 'handles calling a proc' do
      'foo.()'.
        must_be_parsed_as s(:call, s(:call, nil, :foo), :call)
    end
  end
end
