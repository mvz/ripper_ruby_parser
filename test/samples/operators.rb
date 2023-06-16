# Samples of different operators

# range operator (..)
0..4
-1..-3
'a'..'z'
0.0..4.0
foo..bar
0..4.0
0.0..4

# exclusive range operator (...)
0...4
-1...-3
'a'...'z'
0.0...4.0
foo...bar
0...4.0

# endless ranges
1..

foo = 2
foo..

# beginless ranges
..1
foo = 2
..foo

# Regex matching
/foo/ =~ bar
foo =~ /bar/
foo =~ bar
/#{foo}/ =~ bar
/(?<foo>bar)/ =~ baz; foo
(/foo/) =~ bar
foo =~ (/bar/)
foo =~ 42
42 =~ foo
"aaa" =~ 42
