# frozen_string_literal: true

require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::SexpHandlers::MethodCalls do
  describe 'when parsing with RipperRubyParser::Parser#parse' do
    describe 'for method calls' do
      describe 'without a receiver' do
        it 'works without parentheses' do
          _('foo bar').
            must_be_parsed_as s(:call, nil, :foo,
                                s(:call, nil, :bar))
        end

        it 'works with parentheses' do
          _('foo(bar)').
            must_be_parsed_as s(:call, nil, :foo,
                                s(:call, nil, :bar))
        end

        it 'works with an empty parameter list and no parentheses' do
          _('foo').
            must_be_parsed_as s(:call, nil, :foo)
        end

        it 'works with parentheses around an empty parameter list' do
          _('foo()').
            must_be_parsed_as s(:call, nil, :foo)
        end

        it 'works for methods ending in a question mark' do
          _('foo?').
            must_be_parsed_as s(:call, nil, :foo?)
        end

        it 'works with nested calls without parentheses' do
          _('foo bar baz').
            must_be_parsed_as s(:call, nil, :foo,
                                s(:call, nil, :bar,
                                  s(:call, nil, :baz)))
        end

        it 'works with a non-final splat argument' do
          _('foo(bar, *baz, qux)').
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:splat, s(:call, nil, :baz)),
                                s(:call, nil, :qux))
        end

        it 'works with a splat argument followed by several regular arguments' do
          _('foo(bar, *baz, qux, quuz)').
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:splat, s(:call, nil, :baz)),
                                s(:call, nil, :qux),
                                s(:call, nil, :quuz))
        end

        it 'works with a named argument' do
          _('foo(bar, baz: qux)').
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:hash, s(:lit, :baz), s(:call, nil, :qux)))
        end

        it 'works with several named arguments' do
          _('foo(bar, baz: qux, quux: quuz)').
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:hash,
                                  s(:lit, :baz), s(:call, nil, :qux),
                                  s(:lit, :quux), s(:call, nil, :quuz)))
        end

        it 'works with a double splat argument' do
          _('foo(bar, **baz)').
            must_be_parsed_as s(:call,
                                nil,
                                :foo,
                                s(:call, nil, :bar),
                                s(:hash,
                                  s(:kwsplat, s(:call, nil, :baz))))
        end

        it 'works with a named argument followed by a double splat argument' do
          _('foo(bar, baz: qux, **quuz)').
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
          _('foo.bar baz').
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz))
        end

        it 'works with parentheses' do
          _('foo.bar(baz)').
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz))
        end

        it 'works with parentheses around a call with no parentheses' do
          _('foo.bar(baz qux)').
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz,
                                  s(:call, nil, :qux)))
        end

        it 'works with nested calls without parentheses' do
          _('foo.bar baz qux').
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz,
                                  s(:call, nil, :qux)))
        end

        it 'does not keep :begin around a method receiver' do
          _('begin; foo; end.bar').
            must_be_parsed_as s(:call, s(:call, nil, :foo), :bar)
        end
      end

      describe 'for collection indexing' do
        it 'works in the simple case' do
          _('foo[bar]').
            must_be_parsed_as s(:call,
                                s(:call, nil, :foo),
                                :[],
                                s(:call, nil, :bar))
        end

        it 'works without any indexes' do
          _('foo[]').must_be_parsed_as s(:call, s(:call, nil, :foo),
                                      :[])
        end

        it 'works with self[]' do
          _('self[foo]').must_be_parsed_as s(:call, s(:self), :[],
                                          s(:call, nil, :foo))
        end
      end

      describe 'safe call' do
        it 'works without arguments' do
          _('foo&.bar').must_be_parsed_as s(:safe_call, s(:call, nil, :foo), :bar)
        end

        it 'works with arguments' do
          _('foo&.bar baz').
            must_be_parsed_as s(:safe_call,
                                s(:call, nil, :foo),
                                :bar,
                                s(:call, nil, :baz))
        end
      end

      describe 'with blocks' do
        it 'works for a do block' do
          _('foo.bar do baz; end').
            must_be_parsed_as s(:iter,
                                s(:call,
                                  s(:call, nil, :foo),
                                  :bar),
                                0,
                                s(:call, nil, :baz))
        end

        it 'works for a do block with several statements' do
          _('foo.bar do baz; qux; end').
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
      specify { _('super').must_be_parsed_as s(:zsuper) }
      specify do
        _('super foo').must_be_parsed_as s(:super,
                                        s(:call, nil, :foo))
      end
      specify do
        _('super foo, bar').must_be_parsed_as s(:super,
                                             s(:call, nil, :foo),
                                             s(:call, nil, :bar))
      end
      specify do
        _('super foo, *bar').must_be_parsed_as s(:super,
                                              s(:call, nil, :foo),
                                              s(:splat,
                                                s(:call, nil, :bar)))
      end
      specify do
        _('super foo, *bar, &baz').
          must_be_parsed_as s(:super,
                              s(:call, nil, :foo),
                              s(:splat, s(:call, nil, :bar)),
                              s(:block_pass, s(:call, nil, :baz)))
      end
    end

    it 'handles calling a proc' do
      _('foo.()').
        must_be_parsed_as s(:call, s(:call, nil, :foo), :call)
    end
  end

  describe 'when processing a Sexp' do
    let(:processor) { RipperRubyParser::SexpProcessor.new }

    describe '#process_command_call' do
      it 'processes a Ruby 2.5 style period Sexp' do
        sexp = s(:call,
                 s(:vcall, s(:@ident, 'foo', s(1, 0))),
                 :'.',
                 s(:@ident, 'bar', s(1, 4)))
        _(processor.process(sexp)).must_equal s(:call, s(:call, nil, :foo), :bar)
      end

      it 'processes a Ruby 2.6 style period Sexp' do
        sexp = s(:call,
                 s(:vcall, s(:@ident, 'foo', s(1, 0))),
                 s(:@period, '.', s(1, 3)),
                 s(:@ident, 'bar', s(1, 4)))
        _(processor.process(sexp)).must_equal s(:call, s(:call, nil, :foo), :bar)
      end

      it 'raises an error for an unknown call operator' do
        sexp = s(:call,
                 s(:vcall, s(:@ident, 'foo', s(1, 0))),
                 :'>.',
                 s(:@ident, 'bar', s(1, 4)))
        _(-> { processor.process(sexp) }).must_raise
      end
    end
  end
end
