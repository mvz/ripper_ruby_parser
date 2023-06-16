# Conditionals

if begin foo end
  bar
end

if begin foo..bar end
  baz
end

if foo
elsif begin bar end
end

if foo
elsif begin bar..baz end
end

if 1
  bar
else
  baz
end

# Pattern matching

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

# One-line pattern matching
def foo
  1 in bar
  2 in baz => qux
end
