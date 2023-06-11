# Samples that need Ruby 2.7 or higher

# Beginless ranges
..1
foo = 2
..foo

# Argument forwarding
def foo(...)
  bar(...)
end

# Pattern matching (experimental)

case foo
in blub
  ## NOTE: ruby_parser treats matched variables as methods in this case
  # p blub
end

case foo
in [bar, baz]
  ## NOTE: ruby_parser treats matched variables as methods in this case
  # quz = bar + baz
end

case foo
in [bar, baz]
  ## NOTE: ruby_parser treats matched variables as methods in this case
  # quz = bar + baz
in blub
  ## NOTE: ruby_parser treats matched variables as methods in this case
  # p blub
end

case foo
in bar, *quuz
  ## NOTE: ruby_parser treats matched variables as methods in this case
  # qux bar, quuz
end

case foo
in { bar: [baz, qux] }
  ## NOTE: ruby_parser treats matched variables as methods in this case
  # quz = bar(baz) + baz
end

def foo
  case bar
    in { baz: }
    quz = quuz(baz)
  end
end

def foo
  case bar
    in [^baz]
    qux = baz
  end
end

# Pattern matching with rightward assignment
def foo
  case bar
    in [Hash => baz, String => quz]
    qux = baz + quz
  end
end

# One-line pattern matching (experimental)
def foo
  1 in bar
  2 in baz => qux
end

# Numbered block parameters
# NOTE: Not yet implemented in ruby_parser
# foos.each do _1.bar; end
# foos.each { _1.bar }
