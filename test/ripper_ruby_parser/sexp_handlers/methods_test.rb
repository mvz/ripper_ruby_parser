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
