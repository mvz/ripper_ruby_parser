# frozen_string_literal: true

require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  let(:parser) { RipperRubyParser::Parser.new }

  describe '#parse' do
    describe 'for single assignment' do
      it 'works when assigning to a namespaced constant' do
        'Foo::Bar = baz'.
          must_be_parsed_as s(:cdecl,
                              s(:colon2, s(:const, :Foo), :Bar),
                              s(:call, nil, :baz))
      end

      it 'works when assigning to constant in the root namespace' do
        '::Foo = bar'.
          must_be_parsed_as s(:cdecl,
                              s(:colon3, :Foo),
                              s(:call, nil, :bar))
      end

      it 'works with blocks' do
        'foo = begin; bar; end'.
          must_be_parsed_as s(:lasgn, :foo, s(:call, nil, :bar))
      end

      describe 'with a right-hand splat' do
        it 'works in the simple case' do
          'foo = *bar'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:svalue,
                                  s(:splat,
                                    s(:call, nil, :bar))))
        end

        it 'works with blocks' do
          'foo = *begin; bar; end'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:svalue, s(:splat, s(:call, nil, :bar))))
        end
      end

      describe 'with several items on the right hand side' do
        it 'works in the simple case' do
          'foo = bar, baz'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:svalue,
                                  s(:array,
                                    s(:call, nil, :bar),
                                    s(:call, nil, :baz))))
        end

        it 'works with a splat' do
          'foo = bar, *baz'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:svalue,
                                  s(:array,
                                    s(:call, nil, :bar),
                                    s(:splat,
                                      s(:call, nil, :baz)))))
        end
      end

      describe 'with an array literal on the right hand side' do
        specify do
          'foo = [bar, baz]'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:array,
                                  s(:call, nil, :bar),
                                  s(:call, nil, :baz)))
        end
      end

      it 'works when assigning to an instance variable' do
        '@foo = bar'.
          must_be_parsed_as s(:iasgn,
                              :@foo,
                              s(:call, nil, :bar))
      end

      it 'works when assigning to a constant' do
        'FOO = bar'.
          must_be_parsed_as s(:cdecl,
                              :FOO,
                              s(:call, nil, :bar))
      end

      it 'works when assigning to a collection element' do
        'foo[bar] = baz'.
          must_be_parsed_as s(:attrasgn,
                              s(:call, nil, :foo),
                              :[]=,
                              s(:call, nil, :bar),
                              s(:call, nil, :baz))
      end

      it 'works when assigning to an attribute' do
        'foo.bar = baz'.
          must_be_parsed_as s(:attrasgn,
                              s(:call, nil, :foo),
                              :bar=,
                              s(:call, nil, :baz))
      end

      describe 'when assigning to a class variable' do
        it 'works outside a method' do
          '@@foo = bar'.
            must_be_parsed_as s(:cvdecl,
                                :@@foo,
                                s(:call, nil, :bar))
        end

        it 'works inside a method' do
          'def foo; @@bar = baz; end'.
            must_be_parsed_as s(:defn,
                                :foo, s(:args),
                                s(:cvasgn, :@@bar, s(:call, nil, :baz)))
        end

        it 'works inside a method with a receiver' do
          'def self.foo; @@bar = baz; end'.
            must_be_parsed_as s(:defs,
                                s(:self),
                                :foo, s(:args),
                                s(:cvasgn, :@@bar, s(:call, nil, :baz)))
        end

        it 'works inside method arguments' do
          'def foo(bar = (@@baz = qux)); end'.
            must_be_parsed_as s(:defn,
                                :foo,
                                s(:args,
                                  s(:lasgn, :bar,
                                    s(:cvasgn, :@@baz, s(:call, nil, :qux)))),
                                s(:nil))
        end

        it 'works inside method arguments of a singleton method' do
          'def self.foo(bar = (@@baz = qux)); end'.
            must_be_parsed_as s(:defs,
                                s(:self),
                                :foo,
                                s(:args,
                                  s(:lasgn, :bar,
                                    s(:cvasgn, :@@baz, s(:call, nil, :qux)))),
                                s(:nil))
        end

        it 'works inside the receiver in a method definition' do
          'def (bar = (@@baz = qux)).foo; end'.
            must_be_parsed_as s(:defs,
                                s(:lasgn, :bar,
                                  s(:cvdecl, :@@baz,
                                    s(:call, nil, :qux))), :foo,
                                s(:args), s(:nil))
        end
      end

      it 'works when assigning to a global variable' do
        '$foo = bar'.
          must_be_parsed_as s(:gasgn,
                              :$foo,
                              s(:call, nil, :bar))
      end

      describe 'with a rescue modifier' do
        it 'works with assigning a bare method call' do
          'foo = bar rescue baz'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:rescue,
                                  s(:call, nil, :bar),
                                  s(:resbody, s(:array), s(:call, nil, :baz))))
        end

        it 'works with a method call with argument' do
          'foo = bar(baz) rescue qux'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:rescue,
                                  s(:call, nil, :bar, s(:call, nil, :baz)),
                                  s(:resbody, s(:array), s(:call, nil, :qux))))
        end

        it 'works with a method call with argument without brackets' do
          expected = if RUBY_VERSION < '2.4.0'
                       s(:rescue,
                         s(:lasgn, :foo, s(:call, nil, :bar, s(:call, nil, :baz))),
                         s(:resbody, s(:array), s(:call, nil, :qux)))
                     else
                       s(:lasgn, :foo,
                         s(:rescue,
                           s(:call, nil, :bar, s(:call, nil, :baz)),
                           s(:resbody, s(:array), s(:call, nil, :qux))))
                     end
          'foo = bar baz rescue qux'.must_be_parsed_as expected
        end

        it 'works with a class method call with argument without brackets' do
          expected = if RUBY_VERSION < '2.4.0'
                       s(:rescue,
                         s(:lasgn, :foo, s(:call, s(:const, :Bar), :baz, s(:call, nil, :qux))),
                         s(:resbody, s(:array), s(:call, nil, :quuz)))
                     else
                       s(:lasgn, :foo,
                         s(:rescue,
                           s(:call, s(:const, :Bar), :baz, s(:call, nil, :qux)),
                           s(:resbody, s(:array), s(:call, nil, :quuz))))
                     end
          'foo = Bar.baz qux rescue quuz'.
            must_be_parsed_as expected
        end
      end

      it 'sets the correct line numbers' do
        result = parser.parse 'foo = {}'
        result.line.must_equal 1
      end
    end

    describe 'for multiple assignment' do
      specify do
        'foo, * = bar'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:splat)),
                              s(:to_ary, s(:call, nil, :bar)))
      end

      specify do
        '(foo, *bar) = baz'.
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:lasgn, :foo),
                                s(:splat, s(:lasgn, :bar))),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      specify do
        '*foo, bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:splat, s(:lasgn, :foo)),
                                s(:lasgn, :bar)),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it 'works with a rescue modifier' do
        'foo, bar = baz rescue qux'.
          must_be_parsed_as s(:rescue,
                              s(:masgn,
                                s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                                s(:to_ary, s(:call, nil, :baz))),
                              s(:resbody, s(:array), s(:call, nil, :qux)))
      end

      it 'works the same number of items on each side' do
        'foo, bar = baz, qux'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                              s(:array,
                                s(:call, nil, :baz),
                                s(:call, nil, :qux)))
      end

      it 'works with a single item on the right-hand side' do
        'foo, bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it 'works with left-hand splat' do
        'foo, *bar = baz, qux'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:splat, s(:lasgn, :bar))),
                              s(:array,
                                s(:call, nil, :baz),
                                s(:call, nil, :qux)))
      end

      it 'works with parentheses around the left-hand side' do
        '(foo, bar) = baz'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it 'works with complex destructuring' do
        'foo, (bar, baz) = qux'.
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:lasgn, :foo),
                                s(:masgn,
                                  s(:array,
                                    s(:lasgn, :bar),
                                    s(:lasgn, :baz)))),
                              s(:to_ary, s(:call, nil, :qux)))
      end

      it 'works with complex destructuring of the value' do
        'foo, (bar, baz) = [qux, [quz, quuz]]'.
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:lasgn, :foo),
                                s(:masgn,
                                  s(:array,
                                    s(:lasgn, :bar),
                                    s(:lasgn, :baz)))),
                              s(:to_ary,
                                s(:array,
                                  s(:call, nil, :qux),
                                  s(:array,
                                    s(:call, nil, :quz),
                                    s(:call, nil, :quuz)))))
      end

      it 'works with instance variables' do
        '@foo, @bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:iasgn, :@foo), s(:iasgn, :@bar)),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it 'works with class variables' do
        '@@foo, @@bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:cvdecl, :@@foo), s(:cvdecl, :@@bar)),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it 'works with attributes' do
        'foo.bar, foo.baz = qux'.
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:attrasgn, s(:call, nil, :foo), :bar=),
                                s(:attrasgn, s(:call, nil, :foo), :baz=)),
                              s(:to_ary, s(:call, nil, :qux)))
      end

      it 'works with collection elements' do
        'foo[1], bar[2] = baz'.
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:attrasgn,
                                  s(:call, nil, :foo), :[]=, s(:lit, 1)),
                                s(:attrasgn,
                                  s(:call, nil, :bar), :[]=, s(:lit, 2))),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it 'works with constants' do
        'Foo, Bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:cdecl, :Foo), s(:cdecl, :Bar)),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it 'works with instance variables and splat' do
        '@foo, *@bar = baz'.
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:iasgn, :@foo),
                                s(:splat, s(:iasgn, :@bar))),
                              s(:to_ary, s(:call, nil, :baz)))
      end

      it 'works with a right-hand single splat' do
        'foo, bar = *baz'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                              s(:splat, s(:call, nil, :baz)))
      end

      it 'works with a splat in a list of values on the right hand' do
        'foo, bar = baz, *qux'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                              s(:array,
                                s(:call, nil, :baz),
                                s(:splat, s(:call, nil, :qux))))
      end

      it 'works with a right-hand single splat with begin..end block' do
        'foo, bar = *begin; baz; end'.
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                              s(:splat,
                                s(:call, nil, :baz)))
      end

      it 'sets the correct line numbers' do
        result = parser.parse 'foo, bar = {}, {}'
        result.line.must_equal 1
      end
    end

    describe 'for assignment to a collection element' do
      it 'handles multiple indices' do
        'foo[bar, baz] = qux'.
          must_be_parsed_as s(:attrasgn,
                              s(:call, nil, :foo),
                              :[]=,
                              s(:call, nil, :bar),
                              s(:call, nil, :baz),
                              s(:call, nil, :qux))
      end
    end

    describe 'for operator assignment' do
      it 'works with +=' do
        'foo += bar'.
          must_be_parsed_as s(:lasgn, :foo,
                              s(:call, s(:lvar, :foo),
                                :+,
                                s(:call, nil, :bar)))
      end

      it 'works with -=' do
        'foo -= bar'.
          must_be_parsed_as s(:lasgn, :foo,
                              s(:call, s(:lvar, :foo),
                                :-,
                                s(:call, nil, :bar)))
      end

      it 'works with *=' do
        'foo *= bar'.
          must_be_parsed_as s(:lasgn, :foo,
                              s(:call, s(:lvar, :foo),
                                :*,
                                s(:call, nil, :bar)))
      end

      it 'works with /=' do
        'foo /= bar'.
          must_be_parsed_as s(:lasgn, :foo,
                              s(:call,
                                s(:lvar, :foo), :/,
                                s(:call, nil, :bar)))
      end

      it 'works with ||=' do
        'foo ||= bar'.
          must_be_parsed_as s(:op_asgn_or,
                              s(:lvar, :foo),
                              s(:lasgn, :foo,
                                s(:call, nil, :bar)))
      end

      it 'works when assigning to an instance variable' do
        '@foo += bar'.
          must_be_parsed_as s(:iasgn, :@foo,
                              s(:call,
                                s(:ivar, :@foo), :+,
                                s(:call, nil, :bar)))
      end

      it 'works when assigning to a collection element' do
        'foo[bar] += baz'.
          must_be_parsed_as s(:op_asgn1,
                              s(:call, nil, :foo),
                              s(:arglist, s(:call, nil, :bar)),
                              :+,
                              s(:call, nil, :baz))
      end

      it 'works with ||= when assigning to a collection element' do
        'foo[bar] ||= baz'.
          must_be_parsed_as s(:op_asgn1,
                              s(:call, nil, :foo),
                              s(:arglist, s(:call, nil, :bar)),
                              :"||",
                              s(:call, nil, :baz))
      end

      it 'works when assigning to an attribute' do
        'foo.bar += baz'.
          must_be_parsed_as s(:op_asgn2,
                              s(:call, nil, :foo),
                              :bar=, :+,
                              s(:call, nil, :baz))
      end

      it 'works with ||= when assigning to an attribute' do
        'foo.bar ||= baz'.
          must_be_parsed_as s(:op_asgn2,
                              s(:call, nil, :foo),
                              :bar=, :'||',
                              s(:call, nil, :baz))
      end

      describe 'assigning to a collection element' do
        it 'handles multiple indices' do
          'foo[bar, baz] += qux'.
            must_be_parsed_as s(:op_asgn1,
                                s(:call, nil, :foo),
                                s(:arglist,
                                  s(:call, nil, :bar),
                                  s(:call, nil, :baz)),
                                :+,
                                s(:call, nil, :qux))
        end

        it 'works with boolean operators' do
          'foo &&= bar'.
            must_be_parsed_as s(:op_asgn_and,
                                s(:lvar, :foo), s(:lasgn, :foo, s(:call, nil, :bar)))
        end

        it 'works with boolean operators and blocks' do
          'foo &&= begin; bar; end'.
            must_be_parsed_as s(:op_asgn_and,
                                s(:lvar, :foo), s(:lasgn, :foo, s(:call, nil, :bar)))
        end

        it 'works with arithmetic operators and blocks' do
          'foo += begin; bar; end'.
            must_be_parsed_as s(:lasgn, :foo,
                                s(:call, s(:lvar, :foo), :+, s(:call, nil, :bar)))
        end
      end
    end
  end
end
