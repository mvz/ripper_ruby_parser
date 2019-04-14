# frozen_string_literal: true

require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  let(:parser) { RipperRubyParser::Parser.new }
  describe '#parse' do
    it 'returns an s-expression' do
      result = parser.parse 'foo'
      result.must_be_instance_of Sexp
    end

    describe 'for an empty program' do
      it 'returns nil' do
        ''.must_be_parsed_as nil
      end
    end

    describe 'for a class declaration' do
      it 'works with a namespaced class name' do
        'class Foo::Bar; end'.
          must_be_parsed_as s(:class,
                              s(:colon2, s(:const, :Foo), :Bar),
                              nil)
      end

      it 'works for singleton classes' do
        'class << self; end'.must_be_parsed_as s(:sclass, s(:self))
      end
    end

    describe 'for a module declaration' do
      it 'works with a simple module name' do
        'module Foo; end'.
          must_be_parsed_as s(:module, :Foo)
      end

      it 'works with a namespaced module name' do
        'module Foo::Bar; end'.
          must_be_parsed_as s(:module,
                              s(:colon2, s(:const, :Foo), :Bar))
      end
    end

    describe 'for empty parentheses' do
      it 'works with lone ()' do
        '()'.must_be_parsed_as s(:nil)
      end
    end

    describe 'for a begin..end block' do
      it 'works with no statements' do
        'begin; end'.
          must_be_parsed_as s(:nil)
      end

      it 'works with one statement' do
        'begin; foo; end'.
          must_be_parsed_as s(:call, nil, :foo)
      end

      it 'works with multiple statements' do
        'begin; foo; bar; end'.
          must_be_parsed_as s(:block,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end
    end

    describe 'for arguments' do
      it 'works for a simple case with splat' do
        'foo *bar'.
          must_be_parsed_as s(:call,
                              nil,
                              :foo,
                              s(:splat, s(:call, nil, :bar)))
      end

      it 'works for a multi-argument case with splat' do
        'foo bar, *baz'.
          must_be_parsed_as s(:call,
                              nil,
                              :foo,
                              s(:call, nil, :bar),
                              s(:splat, s(:call, nil, :baz)))
      end

      it 'works for a simple case passing a block' do
        'foo &bar'.
          must_be_parsed_as s(:call, nil, :foo,
                              s(:block_pass,
                                s(:call, nil, :bar)))
      end

      it 'works for a bare hash' do
        'foo bar => baz'.
          must_be_parsed_as s(:call, nil, :foo,
                              s(:hash,
                                s(:call, nil, :bar),
                                s(:call, nil, :baz)))
      end
    end

    describe 'for the __ENCODING__ keyword' do
      it 'evaluates to the equivalent of Encoding::UTF_8' do
        '__ENCODING__'.
          must_be_parsed_as s(:colon2, s(:const, :Encoding), :UTF_8)
      end
    end

    describe 'for the __FILE__ keyword' do
      describe 'when not passing a file name' do
        it "creates a string sexp with value '(string)'" do
          '__FILE__'.
            must_be_parsed_as s(:str, '(string)')
        end
      end

      describe 'when passing a file name' do
        it 'creates a string sexp with the file name' do
          result = parser.parse '__FILE__', 'foo'
          result.must_equal s(:str, 'foo')
        end
      end
    end

    describe 'for the __LINE__ keyword' do
      it 'creates a literal sexp with value of the line number' do
        '__LINE__'.
          must_be_parsed_as s(:lit, 1)
        "\n__LINE__".
          must_be_parsed_as s(:lit, 2)
      end
    end

    describe 'for the END keyword' do
      it 'converts to a :postexe iterator' do
        'END { foo }'.
          must_be_parsed_as s(:iter, s(:postexe), 0, s(:call, nil, :foo))
      end

      it 'works with an empty block' do
        'END { }'.
          must_be_parsed_as s(:iter, s(:postexe), 0)
      end
    end

    describe 'for the BEGIN keyword' do
      it 'converts to a :preexe iterator' do
        'BEGIN { foo }'.
          must_be_parsed_as s(:iter, s(:preexe), 0, s(:call, nil, :foo))
      end

      it 'works with an empty block' do
        'BEGIN { }'.
          must_be_parsed_as s(:iter, s(:preexe), 0)
      end

      it 'assigns correct line numbers' do
        "BEGIN {\nfoo\n}".
          must_be_parsed_as s(:iter,
                              s(:preexe).line(1), 0,
                              s(:call, nil, :foo).line(2)).line(1),
                            with_line_numbers: true
      end

      it 'assigns correct line numbers to a embedded begin block' do
        "BEGIN {\nbegin\nfoo\nend\n}".
          must_be_parsed_as s(:iter,
                              s(:preexe).line(1), 0,
                              s(:begin,
                                s(:call, nil, :foo).line(3)).line(2)).line(1),
                            with_line_numbers: true
      end
    end

    describe 'for constant lookups' do
      it 'works when explicitely starting from the root namespace' do
        '::Foo'.
          must_be_parsed_as s(:colon3, :Foo)
      end

      it 'works with a three-level constant lookup' do
        'Foo::Bar::Baz'.
          must_be_parsed_as s(:colon2,
                              s(:colon2, s(:const, :Foo), :Bar),
                              :Baz)
      end

      it 'works looking up a constant in a non-constant' do
        'foo::Bar'.must_be_parsed_as s(:colon2,
                                       s(:call, nil, :foo),
                                       :Bar)
      end
    end

    describe 'for variable references' do
      it 'works for self' do
        'self'.
          must_be_parsed_as s(:self)
      end

      it 'works for instance variables' do
        '@foo'.
          must_be_parsed_as s(:ivar, :@foo)
      end

      it 'works for global variables' do
        '$foo'.
          must_be_parsed_as s(:gvar, :$foo)
      end

      it 'works for regexp match references' do
        '$1'.
          must_be_parsed_as s(:nth_ref, 1)
      end

      specify { "$'".must_be_parsed_as s(:back_ref, :"'") }
      specify { '$&'.must_be_parsed_as s(:back_ref, :"&") }

      it 'works for class variables' do
        '@@foo'.
          must_be_parsed_as s(:cvar, :@@foo)
      end
    end

    describe 'for expressions' do
      it 'handles assignment inside binary operator expressions' do
        'foo + (bar = baz)'.
          must_be_parsed_as s(:call,
                              s(:call, nil, :foo),
                              :+,
                              s(:lasgn,
                                :bar,
                                s(:call, nil, :baz)))
      end

      it 'handles assignment inside unary operator expressions' do
        '+(foo = bar)'.
          must_be_parsed_as s(:call,
                              s(:lasgn, :foo, s(:call, nil, :bar)),
                              :+@)
      end
    end

    # Note: differences in the handling of comments are not caught by Sexp's
    # implementation of equality.
    describe 'for comments' do
      it 'handles method comments' do
        result = parser.parse "# Foo\ndef foo; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args), s(:nil))
        result.comments.must_equal "# Foo\n"
      end

      it 'handles comments for methods with explicit receiver' do
        result = parser.parse "# Foo\ndef foo.bar; end"
        result.must_equal s(:defs,
                            s(:call, nil, :foo),
                            :bar,
                            s(:args),
                            s(:nil))
        result.comments.must_equal "# Foo\n"
      end

      it 'matches comments to the correct entity' do
        result = parser.parse "# Foo\nclass Foo\n# Bar\ndef bar\nend\nend"
        result.must_equal s(:class, :Foo, nil,
                            s(:defn, :bar,
                              s(:args), s(:nil)))
        result.comments.must_equal "# Foo\n"
        defn = result[3]
        defn.sexp_type.must_equal :defn
        defn.comments.must_equal "# Bar\n"
      end

      it 'combines multi-line comments' do
        result = parser.parse "# Foo\n# Bar\ndef foo; end"
        result.must_equal s(:defn,
                            :foo,
                            s(:args), s(:nil))
        result.comments.must_equal "# Foo\n# Bar\n"
      end

      it 'drops comments inside method bodies' do
        result = parser.parse <<-END
          # Foo
          class Foo
            # foo
            def foo
              bar # this is dropped
            end

            # bar
            def bar
              baz
            end
          end
        END
        result.must_equal s(:class,
                            :Foo,
                            nil,
                            s(:defn, :foo, s(:args), s(:call, nil, :bar)),
                            s(:defn, :bar, s(:args), s(:call, nil, :baz)))
        result.comments.must_equal "# Foo\n"
        result[3].comments.must_equal "# foo\n"
        result[4].comments.must_equal "# bar\n"
      end

      it 'handles use of singleton class inside methods' do
        result = parser.parse "# Foo\ndef bar\nclass << self\nbaz\nend\nend"
        result.must_equal s(:defn,
                            :bar,
                            s(:args),
                            s(:sclass, s(:self),
                              s(:call, nil, :baz)))
        result.comments.must_equal "# Foo\n"
      end

      # TODO: Prefer assigning comment to the BEGIN instead
      it 'assigns comments on BEGIN blocks to the following item' do
        result = parser.parse "# Bar\nBEGIN { }\n# Foo\nclass Bar\n# foo\ndef foo; end\nend"
        result.must_equal s(:block,
                            s(:iter, s(:preexe), 0),
                            s(:class, :Bar, nil,
                              s(:defn, :foo, s(:args), s(:nil))))
        result[2].comments.must_equal "# Bar\n# Foo\n"
        result[2][3].comments.must_equal "# foo\n"
      end

      it 'assigns comments on multiple BEGIN blocks to the following item' do
        result = parser.parse "# Bar\nBEGIN { }\n# Baz\nBEGIN { }\n# Foo\ndef foo; end"
        result.must_equal s(:block,
                            s(:iter, s(:preexe), 0),
                            s(:iter, s(:preexe), 0),
                            s(:defn, :foo, s(:args), s(:nil)))
        result[3].comments.must_equal "# Bar\n# Baz\n# Foo\n"
      end

      it 'assigns comments on BEGIN blocks to the first following item' do
        result = parser.parse "# Bar\nBEGIN { }\n# Baz\nBEGIN { }\n# Foo\ndef foo; end"
        result.must_equal s(:block,
                            s(:iter, s(:preexe), 0),
                            s(:iter, s(:preexe), 0),
                            s(:defn, :foo, s(:args), s(:nil)))
        result[3].comments.must_equal "# Bar\n# Baz\n# Foo\n"
      end
    end

    # Note: differences in the handling of line numbers are not caught by
    # Sexp's implementation of equality.
    describe 'assigning line numbers' do
      it 'works for a plain method call' do
        result = parser.parse 'foo'
        result.line.must_equal 1
      end

      it 'works for a method call with parentheses' do
        result = parser.parse 'foo()'
        result.line.must_equal 1
      end

      it 'works for a method call with receiver' do
        result = parser.parse 'foo.bar'
        result.line.must_equal 1
      end

      it 'works for a method call with receiver and arguments' do
        result = parser.parse 'foo.bar baz'
        result.line.must_equal 1
      end

      it 'works for a method call with arguments' do
        result = parser.parse 'foo bar'
        result.line.must_equal 1
      end

      it 'works for a block with two lines' do
        result = parser.parse "foo\nbar\n"
        result.sexp_type.must_equal :block
        result[1].line.must_equal 1
        result[2].line.must_equal 2
        result.line.must_equal 1
      end

      it 'works for a constant reference' do
        result = parser.parse 'Foo'
        result.line.must_equal 1
      end

      it 'works for an instance variable' do
        result = parser.parse '@foo'
        result.line.must_equal 1
      end

      it 'works for a global variable' do
        result = parser.parse '$foo'
        result.line.must_equal 1
      end

      it 'works for a class variable' do
        result = parser.parse '@@foo'
        result.line.must_equal 1
      end

      it 'works for a local variable' do
        "foo = bar\nfoo\n".
          must_be_parsed_as s(:block,
                              s(:lasgn, :foo, s(:call, nil, :bar).line(1)).line(1),
                              s(:lvar, :foo).line(2)).line(1),
                            with_line_numbers: true
      end

      it 'works for an integer literal' do
        result = parser.parse '42'
        result.line.must_equal 1
      end

      it 'works for a float literal' do
        result = parser.parse '3.14'
        result.line.must_equal 1
      end

      it 'works for a range literal' do
        result = parser.parse '0..4'
        result.line.must_equal 1
      end

      it 'works for an exclusive range literal' do
        result = parser.parse '0...4'
        result.line.must_equal 1
      end

      it 'works for a symbol literal' do
        result = parser.parse ':foo'
        result.line.must_equal 1
      end

      it 'works for a keyword-like symbol literal' do
        result = parser.parse ':and'
        result.line.must_equal 1
      end

      it 'works for a string literal' do
        result = parser.parse '"foo"'
        result.line.must_equal 1
      end

      it 'works for a backtick string literal' do
        result = parser.parse '`foo`'
        result.line.must_equal 1
      end

      it 'works for a plain regexp literal' do
        result = parser.parse '/foo/'
        result.line.must_equal 1
      end

      it 'works for a regular expression back reference' do
        result = parser.parse '$1'
        result.line.must_equal 1
      end

      it 'works for self' do
        result = parser.parse 'self'
        result.line.must_equal 1
      end

      it 'works for __FILE__' do
        result = parser.parse '__FILE__'
        result.line.must_equal 1
      end

      it 'works for nil' do
        result = parser.parse 'nil'
        result.line.must_equal 1
      end

      it 'works for a class definition' do
        result = parser.parse 'class Foo; end'
        result.line.must_equal 1
      end

      it 'works for a module definition' do
        result = parser.parse 'module Foo; end'
        result.line.must_equal 1
      end

      it 'works for a method definition' do
        result = parser.parse 'def foo; end'
        result.line.must_equal 1
      end

      it 'assigns line numbers to nested sexps without their own line numbers' do
        "foo(bar) do\nnext baz\nend\n".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo, s(:call, nil, :bar).line(1)).line(1),
                              0,
                              s(:next, s(:call, nil, :baz).line(2)).line(2)).line(1),
                            with_line_numbers: true
      end

      describe 'when a line number is passed' do
        it 'shifts all line numbers as appropriate' do
          result = parser.parse "foo\nbar\n", '(string)', 3
          result.must_equal s(:block,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
          result.line.must_equal 3
          result[1].line.must_equal 3
          result[2].line.must_equal 4
        end
      end
    end
  end

  describe '#trickle_up_line_numbers' do
    it 'works through several nested levels' do
      inner = s(:foo)
      outer = s(:bar, s(:baz, s(:qux, inner)))
      outer.line = 42
      parser.send :trickle_down_line_numbers, outer
      inner.line.must_equal 42
    end
  end

  describe '#trickle_down_line_numbers' do
    it 'works through several nested levels' do
      inner = s(:foo)
      inner.line = 42
      outer = s(:bar, s(:baz, s(:qux, inner)))
      parser.send :trickle_up_line_numbers, outer
      outer.line.must_equal 42
    end
  end
end
