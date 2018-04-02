# Samples of strings demonstrating handling of encoding and line continuations.

# Encoding
"日本語"
"\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E"  # => "日本語"
"\xAB\xE6\x97\xA5"                      # Invalid in UTF8

<<EOS
日本語
EOS

<<EOS
\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E
EOS

# Line continuation
"foo\
bar"
'foo\
bar'
/foo\
bar/
<<EOS
foo\
bar
EOS
