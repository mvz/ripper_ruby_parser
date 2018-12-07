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
  end
end
