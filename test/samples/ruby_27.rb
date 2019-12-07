# Samples that need Ruby 2.7 or higher

# Beginless ranges
..1
..foo

# Argument forwarding
def foo(...)
  bar(...)
  bar(qux, ...)
end

# Pattern matching (experimental)

## NOTE: ruby_parser treats matched variables as methods in this case
# case foo
#   in blub
#   p blub
# end

## NOTE: ruby_parser treats matched variables as methods in this case
# case foo
#   in [bar, baz]
#   quz = bar + baz
# end

## NOTE: ruby_parser treats matched variables as methods in this case
# case foo
#   in [bar, baz]
#   quz = bar + baz
#   in blub
#   p blub
# end

## NOTE: ruby_parser treats matched variables as methods in this case
# case foo
#   in { bar: [baz, qux] }
#   quz = bar(baz) + baz
# end

case foo
  in { bar: }
  quz = quuz(bar)
end

# One-line pattern matching (experimental)
1 in foo
2 in bar => baz

# Numbered block parameters
# NOTE: Not yet implemented in ruby_parser
# foos.each do _1.bar; end
# foos.each { _1.bar }
