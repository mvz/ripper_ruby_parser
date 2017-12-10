require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe '#parse' do
    describe 'for negated operators' do
      specify do
        'foo !~ bar'.must_be_parsed_as s(:not,
                                         s(:call,
                                           s(:call, nil, :foo),
                                           :=~,
                                           s(:call, nil, :bar)))
      end
    end

    describe 'for boolean operators' do
      it 'handles :and' do
        'foo and bar'.
          must_be_parsed_as s(:and,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it 'handles double :and' do
        'foo and bar and baz'.
          must_be_parsed_as s(:and,
                              s(:call, nil, :foo),
                              s(:and,
                                s(:call, nil, :bar),
                                s(:call, nil, :baz)))
      end

      it 'handles :or' do
        'foo or bar'.
          must_be_parsed_as s(:or,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it 'handles double :or' do
        'foo or bar or baz'.
          must_be_parsed_as s(:or,
                              s(:call, nil, :foo),
                              s(:or,
                                s(:call, nil, :bar),
                                s(:call, nil, :baz)))
      end

      it 'handles :or after :and' do
        'foo and bar or baz'.
          must_be_parsed_as s(:or,
                              s(:and,
                                s(:call, nil, :foo),
                                s(:call, nil, :bar)),
                              s(:call, nil, :baz))
      end

      it 'handles :and after :or' do
        'foo or bar and baz'.
          must_be_parsed_as s(:and,
                              s(:or,
                                s(:call, nil, :foo),
                                s(:call, nil, :bar)),
                              s(:call, nil, :baz))
      end

      it 'converts :&& to :and' do
        'foo && bar'.
          must_be_parsed_as s(:and,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it 'handles :|| after :&&' do
        'foo && bar || baz'.
          must_be_parsed_as s(:or,
                              s(:and,
                                s(:call, nil, :foo),
                                s(:call, nil, :bar)),
                              s(:call, nil, :baz))
      end

      it 'handles :&& after :||' do
        'foo || bar && baz'.
          must_be_parsed_as s(:or,
                              s(:call, nil, :foo),
                              s(:and,
                                s(:call, nil, :bar),
                                s(:call, nil, :baz)))
      end

      it 'handles :|| with parentheses' do
        '(foo || bar) || baz'.
          must_be_parsed_as s(:or,
                              s(:or,
                                s(:call, nil, :foo),
                                s(:call, nil, :bar)),
                              s(:call, nil, :baz))
      end

      it 'handles nested :|| with parentheses' do
        'foo || (bar || baz) || qux'.
          must_be_parsed_as  s(:or,
                               s(:call, nil, :foo),
                               s(:or,
                                 s(:or, s(:call, nil, :bar), s(:call, nil, :baz)),
                                 s(:call, nil, :qux)))
      end

      it 'converts :|| to :or' do
        'foo || bar'.
          must_be_parsed_as s(:or,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it 'handles triple :and' do
        'foo and bar and baz and qux'.
          must_be_parsed_as s(:and,
                              s(:call, nil, :foo),
                              s(:and,
                                s(:call, nil, :bar),
                                s(:and,
                                  s(:call, nil, :baz),
                                  s(:call, nil, :qux))))
      end

      it 'handles triple :&&' do
        'foo && bar && baz && qux'.
          must_be_parsed_as s(:and,
                              s(:call, nil, :foo),
                              s(:and,
                                s(:call, nil, :bar),
                                s(:and,
                                  s(:call, nil, :baz),
                                  s(:call, nil, :qux))))
      end
    end

    describe 'for unary numerical operators' do
      it 'handles unary minus with an integer literal' do
        '- 1'.must_be_parsed_as s(:call, s(:lit, 1), :-@)
      end

      it 'handles unary minus with a float literal' do
        '- 3.14'.must_be_parsed_as s(:call, s(:lit, 3.14), :-@)
      end

      it 'handles unary minus with a non-literal' do
        '-foo'.
          must_be_parsed_as s(:call,
                              s(:call, nil, :foo),
                              :-@)
      end

      it 'handles unary minus with a negative number literal' do
        '- -1'.must_be_parsed_as s(:call, s(:lit, -1), :-@)
      end

      it 'handles unary plus with a number literal' do
        '+ 1'.must_be_parsed_as s(:call, s(:lit, 1), :+@)
      end

      it 'handles unary plus with a non-literal' do
        '+foo'.
          must_be_parsed_as s(:call,
                              s(:call, nil, :foo),
                              :+@)
      end
    end
  end
end
