# frozen_string_literal: true

require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe '#parse' do
    describe 'for instance method definitions' do
      it 'treats kwargs as a local variable' do
        'def foo(**bar); bar; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :"**bar"),
                              s(:lvar, :bar))
      end

      it 'treats kwargs as a local variable when other arguments are present' do
        'def foo(bar, **baz); baz; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :bar, :"**baz"),
                              s(:lvar, :baz))
      end

      it 'treats kwargs as a local variable when an explicit block is present' do
        'def foo(**bar, &baz); bar; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :"**bar", :"&baz"),
                              s(:lvar, :bar))
      end

      # NOTE: See https://github.com/seattlerb/ruby_parser/issues/276
      it 'treats kwargs as a method call in a block with kwargs' do
        'def foo(**bar); baz { |**qux| bar; qux }; end'.
          must_be_parsed_as s(:defn, :foo,
                              s(:args, :"**bar"),
                              s(:iter,
                                s(:call, nil, :baz),
                                s(:args, :"**qux"),
                                s(:block,
                                  s(:lvar, :bar),
                                  s(:call, nil, :qux))))
      end

      it 'works with a method argument with a default value' do
        'def foo bar=nil; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, s(:lasgn, :bar, s(:nil))),
                              s(:nil))
      end

      it 'works with several method arguments with default values' do
        'def foo bar=1, baz=2; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:lasgn, :bar, s(:lit, 1)),
                                s(:lasgn, :baz, s(:lit, 2))),
                              s(:nil))
      end

      it 'works with parentheses around the parameter list' do
        'def foo(bar); end'.
          must_be_parsed_as s(:defn, :foo, s(:args, :bar), s(:nil))
      end

      it 'works with a simple splat' do
        'def foo *bar; end'.
          must_be_parsed_as s(:defn, :foo, s(:args, :"*bar"), s(:nil))
      end

      it 'works with a regular argument plus splat' do
        'def foo bar, *baz; end'.
          must_be_parsed_as s(:defn, :foo, s(:args, :bar, :"*baz"), s(:nil))
      end

      it 'works with a nameless splat' do
        'def foo *; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :"*"),
                              s(:nil))
      end

      it 'works for a simple case with explicit block parameter' do
        'def foo &bar; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :"&bar"),
                              s(:nil))
      end

      it 'works with a regular argument plus explicit block parameter' do
        'def foo bar, &baz; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :bar, :"&baz"),
                              s(:nil))
      end

      it 'works with a default value plus explicit block parameter' do
        'def foo bar=1, &baz; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:lasgn, :bar, s(:lit, 1)),
                                :"&baz"),
                              s(:nil))
      end

      it 'works with a default value plus mandatory argument' do
        'def foo bar=1, baz; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:lasgn, :bar, s(:lit, 1)),
                                :baz),
                              s(:nil))
      end

      it 'works with a splat plus explicit block parameter' do
        'def foo *bar, &baz; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :"*bar", :"&baz"),
                              s(:nil))
      end

      it 'works with a default value plus splat' do
        'def foo bar=1, *baz; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:lasgn, :bar, s(:lit, 1)),
                                :"*baz"),
                              s(:nil))
      end

      it 'works with a default value, splat, plus final mandatory arguments' do
        'def foo bar=1, *baz, qux, quuz; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:lasgn, :bar, s(:lit, 1)),
                                :"*baz", :qux, :quuz),
                              s(:nil))
      end

      it 'works with a named argument with a default value' do
        'def foo bar: 1; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:kwarg, :bar, s(:lit, 1))),
                              s(:nil))
      end

      it 'works with a named argument with no default value' do
        'def foo bar:; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args,
                                s(:kwarg, :bar)),
                              s(:nil))
      end

      it 'works with a double splat' do
        'def foo **bar; end'.
          must_be_parsed_as s(:defn,
                              :foo,
                              s(:args, :'**bar'),
                              s(:nil))
      end

      it 'works when the method name is an operator' do
        'def +; end'.
          must_be_parsed_as s(:defn, :+, s(:args),
                              s(:nil))
      end
    end

    describe 'for singleton method definitions' do
      it 'works with empty body' do
        'def foo.bar; end'.
          must_be_parsed_as s(:defs,
                              s(:call, nil, :foo),
                              :bar,
                              s(:args),
                              s(:nil))
      end

      it 'works with a body with multiple statements' do
        'def foo.bar; baz; qux; end'.
          must_be_parsed_as s(:defs,
                              s(:call, nil, :foo),
                              :bar,
                              s(:args),
                              s(:call, nil, :baz),
                              s(:call, nil, :qux))
      end
    end

    describe 'for the alias statement' do
      it 'works with regular barewords' do
        'alias foo bar'.
          must_be_parsed_as s(:alias,
                              s(:lit, :foo), s(:lit, :bar))
      end

      it 'works with symbols' do
        'alias :foo :bar'.
          must_be_parsed_as s(:alias,
                              s(:lit, :foo), s(:lit, :bar))
      end

      it 'works with operator barewords' do
        'alias + -'.
          must_be_parsed_as s(:alias,
                              s(:lit, :+), s(:lit, :-))
      end

      it 'treats keywords as symbols' do
        'alias next foo'.
          must_be_parsed_as s(:alias, s(:lit, :next), s(:lit, :foo))
      end

      it 'works with global variables' do
        'alias $foo $bar'.
          must_be_parsed_as s(:valias, :$foo, :$bar)
      end
    end

    describe 'for the undef statement' do
      it 'works with a single bareword identifier' do
        'undef foo'.
          must_be_parsed_as s(:undef, s(:lit, :foo))
      end

      it 'works with a single symbol' do
        'undef :foo'.
          must_be_parsed_as s(:undef, s(:lit, :foo))
      end

      it 'works with multiple bareword identifiers' do
        'undef foo, bar'.
          must_be_parsed_as s(:block,
                              s(:undef, s(:lit, :foo)),
                              s(:undef, s(:lit, :bar)))
      end

      it 'works with multiple bareword symbols' do
        'undef :foo, :bar'.
          must_be_parsed_as s(:block,
                              s(:undef, s(:lit, :foo)),
                              s(:undef, s(:lit, :bar)))
      end
    end
  end
end
