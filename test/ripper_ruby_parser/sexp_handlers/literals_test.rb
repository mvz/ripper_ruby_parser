# frozen_string_literal: true

require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  let(:parser) { RipperRubyParser::Parser.new }

  describe '#parse' do
    describe 'for regexp literals' do
      it 'works for a simple regex literal' do
        '/foo/'.
          must_be_parsed_as s(:lit, /foo/)
      end

      it 'works for regex literals with escaped right parenthesis' do
        '/\\)/'.
          must_be_parsed_as s(:lit, /\)/)
      end

      it 'works for regex literals with escape sequences' do
        '/\\)\\n\\\\/'.
          must_be_parsed_as s(:lit, /\)\n\\/)
      end

      it 'does not fix encoding' do
        '/2\302\275/'.
          must_be_parsed_as s(:lit, /2\302\275/)
      end

      it 'works for a regex literal with the multiline flag' do
        '/foo/m'.
          must_be_parsed_as s(:lit, /foo/m)
      end

      it 'works for a regex literal with the extended flag' do
        '/foo/x'.
          must_be_parsed_as s(:lit, /foo/x)
      end

      it 'works for a regex literal with the ignorecase flag' do
        '/foo/i'.
          must_be_parsed_as s(:lit, /foo/i)
      end

      it 'works for a regex literal with a combination of flags' do
        '/foo/ixmn'.
          must_be_parsed_as s(:lit, /foo/mixn)
      end

      it 'works with the no-encoding flag' do
        '/foo/n'.
          must_be_parsed_as s(:lit, /foo/n)
      end

      it 'works with line continuation' do
        "/foo\\\nbar/".
          must_be_parsed_as s(:lit, /foobar/)
      end

      describe 'for a %r-delimited regex literal' do
        it 'works for the simple case with escape sequences' do
          '%r[foo\nbar]'.
            must_be_parsed_as s(:lit, /foo\nbar/)
        end

        it 'works with odd delimiters and escape sequences' do
          '%r_foo\nbar_'.
            must_be_parsed_as s(:lit, /foo\nbar/)
        end
      end

      describe 'with interpolations' do
        it 'works for a simple interpolation' do
          '/foo#{bar}baz/'.
            must_be_parsed_as s(:dregx,
                                'foo',
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, 'baz'))
        end

        it 'works for a simple interpolation in extra-compatible mode' do
          '/foo#{bar}baz/'.
            must_be_parsed_as s(:dregx,
                                'foo',
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, 'baz')),
                              extra_compatible: true
        end

        it 'works for a regex literal with flags and interpolation' do
          '/foo#{bar}/ixm'.
            must_be_parsed_as s(:dregx,
                                'foo',
                                s(:evstr, s(:call, nil, :bar)),
                                7)
        end

        it 'works with the no-encoding flag' do
          '/foo#{bar}/n'.
            must_be_parsed_as s(:dregx,
                                'foo',
                                s(:evstr,
                                  s(:call, nil, :bar)), 32)
        end

        it 'works with the unicode-encoding flag' do
          '/foo#{bar}/u'.
            must_be_parsed_as s(:dregx,
                                'foo',
                                s(:evstr,
                                  s(:call, nil, :bar)), 16)
        end

        it 'works with unicode flag plus other flag' do
          '/foo#{bar}/un'.
            must_be_parsed_as s(:dregx,
                                'foo',
                                s(:evstr,
                                  s(:call, nil, :bar)), 48)
        end

        it 'works with the euc-encoding flag' do
          '/foo#{bar}/e'.
            must_be_parsed_as s(:dregx,
                                'foo',
                                s(:evstr,
                                  s(:call, nil, :bar)), 16)
        end

        it 'works with the sjis-encoding flag' do
          '/foo#{bar}/s'.
            must_be_parsed_as s(:dregx,
                                'foo',
                                s(:evstr,
                                  s(:call, nil, :bar)), 16)
        end

        it 'works for a regex literal with interpolate-once flag' do
          '/foo#{bar}/o'.
            must_be_parsed_as s(:dregx_once,
                                'foo',
                                s(:evstr, s(:call, nil, :bar)))
        end

        it 'works with an empty interpolation' do
          '/foo#{}bar/'.
            must_be_parsed_as s(:dregx,
                                'foo',
                                s(:evstr),
                                s(:str, 'bar'))
        end

        describe 'containing just a literal string' do
          it 'performs the interpolation when it is at the end' do
            '/foo#{"bar"}/'.must_be_parsed_as s(:lit, /foobar/)
          end

          it 'performs the interpolation when it is in the middle' do
            '/foo#{"bar"}baz/'.must_be_parsed_as s(:lit, /foobarbaz/)
          end

          it 'performs the interpolation when it is at the start' do
            '/#{"foo"}bar/'.must_be_parsed_as s(:lit, /foobar/)
          end
        end
      end
    end

    describe 'for string literals' do
      it 'works for empty strings' do
        "''".
          must_be_parsed_as s(:str, '')
      end

      it 'sets the encoding for literal strings to utf8 even if ascii would do' do
        parser = RipperRubyParser::Parser.new
        result = parser.parse '"foo"'
        result.must_equal s(:str, 'foo')
        result[1].encoding.to_s.must_equal 'UTF-8'
      end

      it 'handles line breaks within double-quoted strings' do
        "\"foo\nbar\"".
          must_be_parsed_as s(:str, "foo\nbar")
      end

      it 'handles line continuation with double-quoted strings' do
        "\"foo\\\nbar\"".
          must_be_parsed_as s(:str, 'foobar')
      end

      it 'escapes line continuation with double-quoted strings' do
        "\"foo\\\\\nbar\"".
          must_be_parsed_as s(:str, "foo\\\nbar")
      end

      describe 'with double-quoted strings with escape sequences' do
        it 'works for strings with escape sequences' do
          '"\\n"'.
            must_be_parsed_as s(:str, "\n")
        end

        it 'works for strings with useless escape sequences' do
          '"F\\OO"'.
            must_be_parsed_as s(:str, 'FOO')
        end

        it 'works for strings with escaped backslashes' do
          '"\\\\n"'.
            must_be_parsed_as s(:str, '\\n')
        end

        it 'works for a representation of a regex literal with escaped right parenthesis' do
          '"/\\\\)/"'.
            must_be_parsed_as s(:str, '/\\)/')
        end

        it 'works for a uselessly escaped right parenthesis' do
          '"/\\)/"'.
            must_be_parsed_as s(:str, '/)/')
        end

        it 'works for a string containing escaped quotes' do
          '"\\""'.
            must_be_parsed_as s(:str, '"')
        end

        it 'works with hex escapes' do
          '"\\x36"'.must_be_parsed_as s(:str, '6')
          '"\\x4a"'.must_be_parsed_as s(:str, 'J')
          '"\\x4A"'.must_be_parsed_as s(:str, 'J')
          '"\\x3Z"'.must_be_parsed_as s(:str, "\x03Z")
        end

        it 'works with single-letter escapes' do
          '"foo\\abar"'.must_be_parsed_as s(:str, "foo\abar")
          '"foo\\bbar"'.must_be_parsed_as s(:str, "foo\bbar")
          '"foo\\ebar"'.must_be_parsed_as s(:str, "foo\ebar")
          '"foo\\fbar"'.must_be_parsed_as s(:str, "foo\fbar")
          '"foo\\nbar"'.must_be_parsed_as s(:str, "foo\nbar")
          '"foo\\rbar"'.must_be_parsed_as s(:str, "foo\rbar")
          '"foo\\sbar"'.must_be_parsed_as s(:str, "foo\sbar")
          '"foo\\tbar"'.must_be_parsed_as s(:str, "foo\tbar")
          '"foo\\vbar"'.must_be_parsed_as s(:str, "foo\vbar")
        end

        it 'works with octal number escapes' do
          '"foo\\123bar"'.must_be_parsed_as s(:str, "foo\123bar")
          '"foo\\23bar"'.must_be_parsed_as s(:str, "foo\023bar")
          '"foo\\3bar"'.must_be_parsed_as s(:str, "foo\003bar")

          '"foo\\118bar"'.must_be_parsed_as s(:str, "foo\0118bar")
          '"foo\\18bar"'.must_be_parsed_as s(:str, "foo\0018bar")
        end

        it 'works with simple short hand control sequence escapes' do
          '"foo\\cabar"'.must_be_parsed_as s(:str, "foo\cabar")
          '"foo\\cZbar"'.must_be_parsed_as s(:str, "foo\cZbar")
        end

        it 'works with simple regular control sequence escapes' do
          '"foo\\C-abar"'.must_be_parsed_as s(:str, "foo\C-abar")
          '"foo\\C-Zbar"'.must_be_parsed_as s(:str, "foo\C-Zbar")
        end

        it 'works with unicode escapes' do
          '"foo\\u273bbar"'.must_be_parsed_as s(:str, 'foo✻bar')
        end

        it 'works with unicode escapes in extra-compatible mode' do
          '"foo\\u273bbar"'.
            must_be_parsed_as s(:str, 'foo✻r'), extra_compatible: true
        end

        it 'works with unicode escapes with braces' do
          '"foo\\u{273b}bar"'.must_be_parsed_as s(:str, 'foo✻bar')
        end

        it 'converts to unicode if possible' do
          '"2\302\275"'.must_be_parsed_as s(:str, '2½')
        end

        it 'converts to unicode if possible in extra-compatible mode' do
          '"2\302\275"'.must_be_parsed_as s(:str, '2½'), extra_compatible: true
        end

        it 'does not convert to unicode if result is not valid' do
          '"2\x82\302\275"'.
            must_be_parsed_as s(:str,
                                (+"2\x82\xC2\xBD").force_encoding('ascii-8bit'))
        end
      end

      describe 'with interpolations containing just a literal string' do
        it 'performs the interpolation when it is at the end' do
          '"foo#{"bar"}"'.must_be_parsed_as s(:str, 'foobar')
        end

        it 'performs the interpolation when it is in the middle' do
          '"foo#{"bar"}baz"'.must_be_parsed_as s(:str, 'foobarbaz')
        end

        it 'performs the interpolation when it is at the start' do
          '"#{"foo"}bar"'.must_be_parsed_as s(:str, 'foobar')
        end
      end

      describe 'with interpolations without braces' do
        it 'works for ivars' do
          "\"foo\#@bar\"".must_be_parsed_as s(:dstr,
                                              'foo',
                                              s(:evstr, s(:ivar, :@bar)))
        end

        it 'works for gvars' do
          "\"foo\#$bar\"".must_be_parsed_as s(:dstr,
                                              'foo',
                                              s(:evstr, s(:gvar, :$bar)))
        end

        it 'works for cvars' do
          "\"foo\#@@bar\"".must_be_parsed_as s(:dstr,
                                               'foo',
                                               s(:evstr, s(:cvar, :@@bar)))
        end
      end

      describe 'with interpolations with braces' do
        it 'works for trivial interpolated strings' do
          '"#{foo}"'.
            must_be_parsed_as s(:dstr,
                                '',
                                s(:evstr,
                                  s(:call, nil, :foo)))
        end

        it 'works for basic interpolated strings' do
          '"foo#{bar}"'.
            must_be_parsed_as s(:dstr,
                                'foo',
                                s(:evstr,
                                  s(:call, nil, :bar)))
        end

        it 'works for strings with several interpolations' do
          '"foo#{bar}baz#{qux}"'.
            must_be_parsed_as s(:dstr,
                                'foo',
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, 'baz'),
                                s(:evstr, s(:call, nil, :qux)))
        end

        it 'correctly handles two interpolations in a row' do
          "\"\#{bar}\#{qux}\"".
            must_be_parsed_as s(:dstr,
                                '',
                                s(:evstr, s(:call, nil, :bar)),
                                s(:evstr, s(:call, nil, :qux)))
        end

        it 'works with an empty interpolation' do
          "\"foo\#{}bar\"".
            must_be_parsed_as s(:dstr,
                                'foo',
                                s(:evstr),
                                s(:str, 'bar'))
        end

        it 'correctly handles interpolation with __FILE__ before another interpolation' do
          "\"foo\#{__FILE__}\#{bar}\"".
            must_be_parsed_as s(:dstr,
                                'foo(string)',
                                s(:evstr, s(:call, nil, :bar)))
        end

        it 'correctly handles interpolation with __FILE__ after another interpolation' do
          "\"\#{bar}foo\#{__FILE__}\"".
            must_be_parsed_as s(:dstr,
                                '',
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, 'foo'),
                                s(:str, '(string)'))
        end

        it 'correctly handles nested interpolation' do
          '"foo#{"bar#{baz}"}"'.
            must_be_parsed_as s(:dstr,
                                'foobar',
                                s(:evstr, s(:call, nil, :baz)))
        end

        it 'correctly handles consecutive nested interpolation' do
          '"foo#{"bar#{baz}"}foo#{"bar#{baz}"}"'.
            must_be_parsed_as s(:dstr,
                                'foobar',
                                s(:evstr, s(:call, nil, :baz)),
                                s(:str, 'foo'),
                                s(:str, 'bar'),
                                s(:evstr, s(:call, nil, :baz)))
        end
      end

      describe 'with interpolations and escape sequences' do
        it 'works when interpolations are followed by escape sequences' do
          '"#{foo}\\n"'.
            must_be_parsed_as s(:dstr,
                                '',
                                s(:evstr, s(:call, nil, :foo)),
                                s(:str, "\n"))
        end

        it 'works when interpolations contain a mix of other string-like literals' do
          '"#{[:foo, \'bar\']}\\n"'.
            must_be_parsed_as s(:dstr,
                                '',
                                s(:evstr, s(:array, s(:lit, :foo), s(:str, 'bar'))),
                                s(:str, "\n"))
        end

        it 'converts to unicode after interpolation' do
          '"#{foo}2\302\275"'.
            must_be_parsed_as s(:dstr,
                                '',
                                s(:evstr, s(:call, nil, :foo)),
                                s(:str, '2½'))
        end

        it 'convert single null byte to unicode after interpolation' do
          '"#{foo}\0"'.
            must_be_parsed_as s(:dstr,
                                '',
                                s(:evstr, s(:call, nil, :foo)),
                                s(:str, "\u0000"))
        end
      end

      describe 'with interpolations and escape sequences in extra-compatible mode' do
        it 'does not convert to unicode after interpolation' do
          '"#{foo}2\302\275"'.
            must_be_parsed_as s(:dstr,
                                '',
                                s(:evstr, s(:call, nil, :foo)),
                                s(:str, (+"2\xC2\xBD").force_encoding('ascii-8bit'))),
                              extra_compatible: true
        end

        it 'keeps single null byte as ascii after interpolation' do
          '"#{foo}\0"'.
            must_be_parsed_as s(:dstr,
                                '',
                                s(:evstr, s(:call, nil, :foo)),
                                s(:str, (+"\x00").force_encoding('ascii-8bit'))),
                              extra_compatible: true
        end

        it 'converts string with null to unicode after interpolation' do
          '"#{foo}bar\0"'.
            must_be_parsed_as s(:dstr,
                                '',
                                s(:evstr, s(:call, nil, :foo)),
                                s(:str, "bar\x00")),
                              extra_compatible: true
        end
      end

      describe 'with single quoted strings' do
        it 'works with escaped single quotes' do
          "'foo\\'bar'".
            must_be_parsed_as s(:str, "foo'bar")
        end

        it 'works with embedded backslashes' do
          "'foo\\abar'".
            must_be_parsed_as s(:str, 'foo\abar')
        end

        it 'works with escaped embedded backslashes' do
          "'foo\\\\abar'".
            must_be_parsed_as s(:str, 'foo\abar')
        end

        it 'works with sequences of backslashes' do
          "'foo\\\\\\abar'".
            must_be_parsed_as s(:str, 'foo\\\\abar')
        end

        it 'does not process line continuation' do
          "'foo\\\nbar'".
            must_be_parsed_as s(:str, "foo\\\nbar")
        end

        it 'handles escape sequences correctly in extra-compatible mode' do
          "'foo\\'bar\\\nbaz\\aqux'".
            must_be_parsed_as s(:str, "foo'bar\\\nbaz\\aqux"),
                              extra_compatible: true
        end
      end

      describe 'with %Q-delimited strings' do
        it 'works for the simple case' do
          '%Q[bar]'.
            must_be_parsed_as s(:str, 'bar')
        end

        it 'works for escape sequences' do
          '%Q[foo\\nbar]'.
            must_be_parsed_as s(:str, "foo\nbar")
        end

        it 'works for multi-line strings' do
          "%Q[foo\nbar]".
            must_be_parsed_as s(:str, "foo\nbar")
        end

        it 'handles line continuation' do
          "%Q[foo\\\nbar]".
            must_be_parsed_as s(:str, 'foobar')
        end
      end

      describe 'with %q-delimited strings' do
        it 'works for the simple case' do
          '%q[bar]'.
            must_be_parsed_as s(:str, 'bar')
        end

        it 'does not handle for escape sequences' do
          '%q[foo\\nbar]'.
            must_be_parsed_as s(:str, 'foo\nbar')
        end

        it 'works for multi-line strings' do
          "%q[foo\nbar]".
            must_be_parsed_as s(:str, "foo\nbar")
        end

        it 'handles line continuation' do
          "%q[foo\\\nbar]".
            must_be_parsed_as s(:str, "foo\\\nbar")
        end
      end

      describe 'with %-delimited strings' do
        it 'works for the simple case' do
          '%(bar)'.
            must_be_parsed_as s(:str, 'bar')
        end

        it 'works for escape sequences' do
          '%(foo\nbar)'.
            must_be_parsed_as s(:str, "foo\nbar")
        end

        it 'works for multiple lines' do
          "%(foo\nbar)".
            must_be_parsed_as s(:str, "foo\nbar")
        end

        it 'works with line continuations' do
          "%(foo\\\nbar)".
            must_be_parsed_as s(:str, 'foobar')
        end

        it 'works for odd delimiters' do
          '%!foo\nbar!'.
            must_be_parsed_as s(:str, "foo\nbar")
        end
      end

      describe 'with string concatenation' do
        it 'performs the concatenation in the case of two simple literal strings' do
          '"foo" "bar"'.must_be_parsed_as s(:str, 'foobar')
        end

        it 'performs the concatenation when the right string has interpolations' do
          "\"foo\" \"bar\#{baz}\"".
            must_be_parsed_as s(:dstr,
                                'foobar',
                                s(:evstr, s(:call, nil, :baz)))
        end

        describe 'when the left string has interpolations' do
          it 'performs the concatenation' do
            "\"foo\#{bar}\" \"baz\"".
              must_be_parsed_as s(:dstr,
                                  'foo',
                                  s(:evstr, s(:call, nil, :bar)),
                                  s(:str, 'baz'))
          end

          it 'performs the concatenation with an empty string' do
            "\"foo\#{bar}\" \"\"".
              must_be_parsed_as s(:dstr,
                                  'foo',
                                  s(:evstr, s(:call, nil, :bar)),
                                  s(:str, ''))
          end
        end

        describe 'when both strings have interpolations' do
          it 'performs the concatenation' do
            "\"foo\#{bar}\" \"baz\#{qux}\"".
              must_be_parsed_as s(:dstr,
                                  'foo',
                                  s(:evstr, s(:call, nil, :bar)),
                                  s(:str, 'baz'),
                                  s(:evstr, s(:call, nil, :qux)))
          end

          it 'removes empty substrings from the concatenation' do
            "\"foo\#{bar}\" \"\#{qux}\"".
              must_be_parsed_as s(:dstr,
                                  'foo',
                                  s(:evstr, s(:call, nil, :bar)),
                                  s(:evstr, s(:call, nil, :qux)))
          end
        end
      end

      describe 'for heredocs' do
        it 'works for the simple case' do
          "<<FOO\nbar\nFOO".
            must_be_parsed_as s(:str, "bar\n")
        end

        it 'works with multiple lines' do
          "<<FOO\nbar\nbaz\nFOO".
            must_be_parsed_as s(:str, "bar\nbaz\n")
        end

        it 'works for the indentable case' do
          "<<-FOO\n  bar\n  FOO".
            must_be_parsed_as s(:str, "  bar\n")
        end

        it 'works for the automatically outdenting case' do
          "  <<~FOO\n  bar\n  FOO".
            must_be_parsed_as s(:str, "bar\n")
        end

        it 'works for escape sequences' do
          "<<FOO\nbar\\tbaz\nFOO".
            must_be_parsed_as s(:str, "bar\tbaz\n")
        end

        it 'works for escape sequences in extra-compatible mode' do
          "<<FOO\nbar\\tbaz\nFOO".
            must_be_parsed_as s(:str, "bar\tbaz\n"),
                              extra_compatible: true
        end

        it 'does not unescape with single quoted version' do
          "<<'FOO'\nbar\\tbaz\nFOO".
            must_be_parsed_as s(:str, "bar\\tbaz\n")
        end

        it 'does not unescape with single quoted version in extra-compatible mode' do
          "<<'FOO'\nbar\\tbaz\nFOO".
            must_be_parsed_as s(:str, "bar\\tbaz\n"),
                              extra_compatible: true
        end

        it 'works with multiple lines with the single quoted version' do
          "<<'FOO'\nbar\nbaz\nFOO".
            must_be_parsed_as s(:str, "bar\nbaz\n")
        end

        it 'does not unescape with indentable single quoted version' do
          "<<-'FOO'\n  bar\\tbaz\n  FOO".
            must_be_parsed_as s(:str, "  bar\\tbaz\n")
        end

        it 'does not unescape the automatically outdenting single quoted version' do
          "<<~'FOO'\n  bar\\tbaz\n  FOO".
            must_be_parsed_as s(:str, "bar\\tbaz\n")
        end

        it 'handles line continuation' do
          "<<FOO\nbar\\\nbaz\nFOO".
            must_be_parsed_as s(:str, "barbaz\n")
        end

        it 'escapes line continuation' do
          "<<FOO\nbar\\\\\nbaz\nFOO".
            must_be_parsed_as s(:str, "bar\\\nbaz\n")
        end

        it 'converts to unicode' do
          "<<FOO\n2\\302\\275\nFOO".
            must_be_parsed_as s(:str, "2½\n")
        end

        it 'does not convert to unicode in extra-compatible mode' do
          "<<FOO\n2\\302\\275\nFOO".
            must_be_parsed_as s(:str,
                                (+"2\xC2\xBD\n").force_encoding('ascii-8bit')),
                              extra_compatible: true
        end

        it 'handles interpolation' do
          "<<FOO\n\#{bar}\nFOO".
            must_be_parsed_as s(:dstr, '',
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, "\n"))
        end

        it 'handles line continuation after interpolation' do
          "<<FOO\n\#{bar}\nbaz\\\nqux\nFOO".
            must_be_parsed_as s(:dstr, '',
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, "\nbazqux\n"))
        end

        it 'handles line continuation after interpolation in extra-compatible mode' do
          "<<FOO\n\#{bar}\nbaz\\\nqux\nFOO".
            must_be_parsed_as s(:dstr, '',
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, "\nbazqux\n")),
                              extra_compatible: true
        end

        it 'handles line continuation after interpolation for the indentable case' do
          "<<-FOO\n\#{bar}\nbaz\\\nqux\nFOO".
            must_be_parsed_as s(:dstr, '',
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, "\nbazqux\n"))
        end
      end
    end

    describe 'for word list literals with %w delimiter' do
      it 'works for the simple case' do
        '%w(foo bar)'.
          must_be_parsed_as s(:array, s(:str, 'foo'), s(:str, 'bar'))
      end

      it 'does not perform interpolation' do
        '%w(foo\\nbar baz)'.
          must_be_parsed_as s(:array, s(:str, 'foo\\nbar'), s(:str, 'baz'))
      end

      it 'handles line continuation' do
        "%w(foo\\\nbar baz)".
          must_be_parsed_as s(:array, s(:str, "foo\nbar"), s(:str, 'baz'))
      end

      it 'handles escaped spaces' do
        '%w(foo bar\ baz)'.
          must_be_parsed_as s(:array, s(:str, 'foo'), s(:str, 'bar baz'))
      end
    end

    describe 'for word list literals with %W delimiter' do
      it 'works for the simple case' do
        '%W(foo bar)'.
          must_be_parsed_as s(:array, s(:str, 'foo'), s(:str, 'bar'))
      end

      it 'handles escaped spaces' do
        '%W(foo bar\ baz)'.
          must_be_parsed_as s(:array, s(:str, 'foo'), s(:str, 'bar baz'))
      end

      it 'correctly handles interpolation' do
        "%W(foo \#{bar} baz)".
          must_be_parsed_as  s(:array,
                               s(:str, 'foo'),
                               s(:dstr, '', s(:evstr, s(:call, nil, :bar))),
                               s(:str, 'baz'))
      end

      it 'correctly handles braceless interpolation' do
        "%W(foo \#@bar baz)".
          must_be_parsed_as  s(:array,
                               s(:str, 'foo'),
                               s(:dstr, '', s(:evstr, s(:ivar, :@bar))),
                               s(:str, 'baz'))
      end

      it 'correctly handles in-word interpolation' do
        "%W(foo \#{bar}baz)".
          must_be_parsed_as s(:array,
                              s(:str, 'foo'),
                              s(:dstr,
                                '',
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, 'baz')))
      end

      it 'correctly handles escape sequences' do
        '%W(foo\nbar baz)'.
          must_be_parsed_as s(:array,
                              s(:str, "foo\nbar"),
                              s(:str, 'baz'))
      end

      it 'converts to unicode if possible' do
        '%W(2\302\275)'.must_be_parsed_as s(:array, s(:str, '2½'))
      end

      it 'does not convert to unicode if possible in extra-compatible mode' do
        '%W(2\302\275)'.
          must_be_parsed_as s(:array,
                              s(:str, (+"2\xC2\xBD").force_encoding('ascii-8bit'))),
                            extra_compatible: true
      end

      it 'correctly handles line continuation' do
        "%W(foo\\\nbar baz)".
          must_be_parsed_as s(:array,
                              s(:str, "foo\nbar"),
                              s(:str, 'baz'))
      end

      it 'correctly handles multiple lines' do
        "%W(foo\nbar baz)".
          must_be_parsed_as s(:array,
                              s(:str, 'foo'),
                              s(:str, 'bar'),
                              s(:str, 'baz'))
      end

      it 'handles escaped spaces in extra-compatible mode' do
        '%W(foo bar\ baz)'.
          must_be_parsed_as s(:array, s(:str, 'foo'), s(:str, 'bar baz')),
                            extra_compatible: true
      end

      it 'correctly handles line continuation in extra-compatible mode' do
        "%W(foo\\\nbar baz)".
          must_be_parsed_as s(:array,
                              s(:str, "foo\nbar"),
                              s(:str, 'baz')),
                            extra_compatible: true
      end
    end

    describe 'for symbol list literals with %i delimiter' do
      it 'works for the simple case' do
        '%i(foo bar)'.
          must_be_parsed_as s(:array, s(:lit, :foo), s(:lit, :bar))
      end

      it 'does not perform interpolation' do
        '%i(foo\\nbar baz)'.
          must_be_parsed_as s(:array, s(:lit, :"foo\\nbar"), s(:lit, :baz))
      end

      it 'handles line continuation' do
        "%i(foo\\\nbar baz)".
          must_be_parsed_as s(:array, s(:lit, :"foo\nbar"), s(:lit, :baz))
      end
    end

    describe 'for symbol list literals with %I delimiter' do
      it 'works for the simple case' do
        '%I(foo bar)'.
          must_be_parsed_as s(:array, s(:lit, :foo), s(:lit, :bar))
      end

      it 'correctly handles escape sequences' do
        '%I(foo\nbar baz)'.
          must_be_parsed_as s(:array,
                              s(:lit, :"foo\nbar"),
                              s(:lit, :baz))
      end

      it 'correctly handles interpolation' do
        "%I(foo \#{bar} baz)".
          must_be_parsed_as s(:array,
                              s(:lit, :foo),
                              s(:dsym, '', s(:evstr, s(:call, nil, :bar))),
                              s(:lit, :baz))
      end

      it 'correctly handles in-word interpolation' do
        "%I(foo \#{bar}baz)".
          must_be_parsed_as s(:array,
                              s(:lit, :foo),
                              s(:dsym,
                                '',
                                s(:evstr, s(:call, nil, :bar)),
                                s(:str, 'baz')))
      end

      it 'correctly handles line continuation' do
        "%I(foo\\\nbar baz)".
          must_be_parsed_as s(:array,
                              s(:lit, :"foo\nbar"),
                              s(:lit, :baz))
      end

      it 'correctly handles multiple lines' do
        "%I(foo\nbar baz)".
          must_be_parsed_as s(:array,
                              s(:lit, :foo),
                              s(:lit, :bar),
                              s(:lit, :baz))
      end
    end

    describe 'for character literals' do
      it 'works for simple character literals' do
        '?a'.
          must_be_parsed_as s(:str, 'a')
      end

      it 'works for escaped character literals' do
        '?\\n'.
          must_be_parsed_as s(:str, "\n")
      end

      it 'works for escaped character literals with ctrl' do
        '?\\C-a'.
          must_be_parsed_as s(:str, "\u0001")
      end

      it 'works for escaped character literals with meta' do
        '?\\M-a'.
          must_be_parsed_as s(:str, (+"\xE1").force_encoding('ascii-8bit'))
      end

      it 'works for escaped character literals with meta plus shorthand ctrl' do
        '?\\M-\\ca'.
          must_be_parsed_as s(:str, (+"\x81").force_encoding('ascii-8bit'))
      end

      it 'works for escaped character literals with shorthand ctrl plus meta' do
        '?\\c\\M-a'.
          must_be_parsed_as s(:str, (+"\x81").force_encoding('ascii-8bit'))
      end

      it 'works for escaped character literals with meta plus ctrl' do
        '?\\M-\\C-a'.
          must_be_parsed_as s(:str, (+"\x81").force_encoding('ascii-8bit'))
      end

      it 'works for escaped character literals with ctrl plus meta' do
        '?\\C-\\M-a'.
          must_be_parsed_as s(:str, (+"\x81").force_encoding('ascii-8bit'))
      end
    end

    describe 'for symbol literals' do
      it 'works for simple symbols' do
        ':foo'.
          must_be_parsed_as s(:lit, :foo)
      end

      it 'works for symbols that look like instance variable names' do
        ':@foo'.
          must_be_parsed_as s(:lit, :@foo)
      end

      it 'works for symbols that look like class names' do
        ':Foo'.
          must_be_parsed_as s(:lit, :Foo)
      end

      it 'works for symbols that look like keywords' do
        ':class'.must_be_parsed_as s(:lit, :class)
      end

      it 'works for :__LINE__' do
        ':__LINE__'.
          must_be_parsed_as s(:lit, :__LINE__)
      end

      it 'works for :__FILE__' do
        ':__FILE__'.
          must_be_parsed_as s(:lit, :__FILE__)
      end

      it 'works for a backtick symbol' do
        ':`'.must_be_parsed_as s(:lit, :`)
      end

      it 'works for simple dsyms' do
        ':"foo"'.
          must_be_parsed_as s(:lit, :foo)
      end

      it 'works for dsyms with interpolations' do
        ':"foo#{bar}"'.
          must_be_parsed_as s(:dsym,
                              'foo',
                              s(:evstr, s(:call, nil, :bar)))
      end

      it 'works for dsyms with interpolations at the start' do
        ':"#{bar}"'.
          must_be_parsed_as s(:dsym,
                              '',
                              s(:evstr, s(:call, nil, :bar)))
      end

      it 'works for dsyms with escape sequences' do
        ':"foo\nbar"'.
          must_be_parsed_as s(:lit, :"foo\nbar")
      end

      it 'works for dsyms with multiple lines' do
        ":\"foo\nbar\"".
          must_be_parsed_as s(:lit, :"foo\nbar")
      end

      it 'works for dsyms with line continuations' do
        ":\"foo\\\nbar\"".
          must_be_parsed_as s(:lit, :foobar)
      end

      it 'works with single quoted dsyms' do
        ":'foo'".
          must_be_parsed_as s(:lit, :foo)
      end

      it 'works with single quoted dsyms with escaped single quotes' do
        ":'foo\\'bar'".
          must_be_parsed_as s(:lit, :'foo\'bar')
      end

      it 'works with single quoted dsyms with multiple lines' do
        ":'foo\nbar'".
          must_be_parsed_as s(:lit, :"foo\nbar")
      end

      it 'works with single quoted dsyms with line continuations' do
        ":'foo\\\nbar'".
          must_be_parsed_as s(:lit, :"foo\\\nbar")
      end

      it 'works with single quoted dsyms with embedded backslashes' do
        ":'foo\\abar'".
          must_be_parsed_as s(:lit, :"foo\\abar")
      end

      it 'works with barewords that need to be interpreted as symbols' do
        'alias foo bar'.
          must_be_parsed_as s(:alias,
                              s(:lit, :foo), s(:lit, :bar))
      end

      it 'assigns a line number to the result' do
        result = parser.parse ':foo'
        result.line.must_equal 1
      end
    end

    describe 'for backtick string literals' do
      it 'works for basic backtick strings' do
        '`foo`'.
          must_be_parsed_as s(:xstr, 'foo')
      end

      it 'works for interpolated backtick strings' do
        '`foo#{bar}`'.
          must_be_parsed_as s(:dxstr,
                              'foo',
                              s(:evstr, s(:call, nil, :bar)))
      end

      it 'works for backtick strings interpolated at the start' do
        '`#{foo}`'.
          must_be_parsed_as s(:dxstr, '',
                              s(:evstr, s(:call, nil, :foo)))
      end

      it 'works for backtick strings with escape sequences' do
        '`foo\\n`'.
          must_be_parsed_as s(:xstr, "foo\n")
      end

      it 'works for backtick strings with multiple lines' do
        "`foo\nbar`".
          must_be_parsed_as s(:xstr, "foo\nbar")
      end

      it 'works for backtick strings with line continuations' do
        "`foo\\\nbar`".
          must_be_parsed_as s(:xstr, 'foobar')
      end
    end

    describe 'for array literals' do
      it 'works for an empty array' do
        '[]'.
          must_be_parsed_as s(:array)
      end

      it 'works for a simple case with splat' do
        '[*foo]'.
          must_be_parsed_as s(:array,
                              s(:splat, s(:call, nil, :foo)))
      end

      it 'works for a multi-element case with splat' do
        '[foo, *bar]'.
          must_be_parsed_as s(:array,
                              s(:call, nil, :foo),
                              s(:splat, s(:call, nil, :bar)))
      end
    end

    describe 'for hash literals' do
      it 'works for an empty hash' do
        '{}'.
          must_be_parsed_as s(:hash)
      end

      it 'works for a hash with one pair' do
        '{foo => bar}'.
          must_be_parsed_as s(:hash,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end

      it 'works for a hash with multiple pairs' do
        '{foo => bar, baz => qux}'.
          must_be_parsed_as s(:hash,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar),
                              s(:call, nil, :baz),
                              s(:call, nil, :qux))
      end

      it 'works for a hash with label keys' do
        '{foo: bar, baz: qux}'.
          must_be_parsed_as s(:hash,
                              s(:lit, :foo),
                              s(:call, nil, :bar),
                              s(:lit, :baz),
                              s(:call, nil, :qux))
      end

      it 'works for a hash with dynamic label keys' do
        "{'foo': bar}".
          must_be_parsed_as s(:hash,
                              s(:lit, :foo),
                              s(:call, nil, :bar))
      end

      it 'works for a hash with splat' do
        '{foo: bar, baz: qux, **quux}'.
          must_be_parsed_as s(:hash,
                              s(:lit, :foo), s(:call, nil, :bar),
                              s(:lit, :baz), s(:call, nil, :qux),
                              s(:kwsplat, s(:call, nil, :quux)))
      end
    end

    describe 'for number literals' do
      it 'works for floats' do
        '3.14'.
          must_be_parsed_as s(:lit, 3.14)
      end

      it 'works for octal integer literals' do
        '0700'.
          must_be_parsed_as s(:lit, 448)
      end

      it 'handles negative sign for integers' do
        '-1'.
          must_be_parsed_as s(:lit, -1)
      end

      it 'handles space after negative sign for integers' do
        '-1 '.
          must_be_parsed_as s(:lit, -1)
      end

      it 'handles negative sign for floats' do
        '-3.14'.
          must_be_parsed_as s(:lit, -3.14)
      end

      it 'handles space after negative sign for floats' do
        '-3.14 '.
          must_be_parsed_as s(:lit, -3.14)
      end

      it 'handles positive sign' do
        '+1'.
          must_be_parsed_as s(:lit, 1)
      end

      it 'works for rationals' do
        '1000r'.
          must_be_parsed_as s(:lit, 1000r)
      end
    end
  end
end
