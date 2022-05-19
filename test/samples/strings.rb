# Samples of strings demonstrating handling of escape sequences, encoding and
# line continuations.

# Escape sequences
%W(foo\nbar baz)
%w(foo\nbar baz)

"foo\u273bbar"
"foo\a\b\e\f\r\s\t\vbar\nbaz"
"\0"
"foo#{bar}\0"
"foo#{bar}baz\0"
"2\302\275"
"#{foo}2\302\275"
%W(2\302\275)
/2\302\275/
"foo\u{101D1}bar"

# Encoding
"日本語"
/日本語/
"\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E"  # => "日本語"
"\xAB\xE6\x97\xA5"                      # Invalid in UTF8
"abc\u3042\x81"                         # Invalid in UTF8

<<EOS
日本語
EOS

<<EOS
\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E
EOS

"\C-a"
"\C-z"
"\C-?"

# Quotes around heredoc names
<<'FOO'
\n
FOO

<<"FOO"
\n
FOO

# Escape sequences in heredocs, in particular carriage returns
#
<<FOO
foo\rbar\tbaz\r
FOO

<<'FOO'
foo\rbar\tbaz\r
FOO

# Dedented heredocs
foo = <<~BAR
  baz
  #{qux}
  quuz
BAR

# Dedented heredocs with interpolation
<<~FOO
  #{bar} smurf
FOO

# Line continuation
"foo\
bar"

'foo2\
bar'

/foo3\
bar/

<<EOS
foo4\
bar
EOS

<<'EOS'
foo4\
bar
EOS

<<EOS
#{bar}
baz \
qux
EOS

<<-EOS
#{bar}
baz \
qux
EOS

%Q[foo5\
bar]

%W[fooa\
bar baz]

%I[foob\
bar baz]

%q[fooc\
bar]

%q[foo\'bar]

%q[foo[bar]baz]

%q[foo\[bar\]baz]

%q[foo\{{\((\<<bar\]baz]

%w[food\
bar baz]

%w[foo\'bar]

%w[foo [bar] baz]

%w[foo \[bar\] baz]

%w[foo \{{ \(( \<< bar\] baz]

%i[fooe\
bar baz]

%r[foof\
bar baz]

# Escaped line continuation
"foo6\\
bar"
'foo7\\
bar'
/foo8\\
bar/
<<EOS
foo9\\
bar
EOS
%Q[foo10\\
bar]
%W[foog\\
bar baz]
%I[fooh\\
bar baz]
%q[fooi\\
bar]
%w[fooj\\
bar baz]
%i[fook\\
bar baz]
%r[fool\\
bar baz]

eval(<<FOO, __FILE__, __LINE__)
bar
baz
FOO

# Interpolation
"foo#{bar}"
"foo#{"bar#{baz}"}"
"foo#{"bar#{"baz#{qux}"}"}"
"foo#{"bar#{baz}"}foo#{"bar#{baz}"}"
"foo#{bar}baz#{__FILE__}qux#{__LINE__}quuz#{zyxxy}"
