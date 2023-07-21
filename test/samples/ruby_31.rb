# Samples that need Ruby 3.1 or higher

# Bare block parameter
def foo &; end

# Endless methods with bodies with arguments without parentheses
def foo = bar 42

# Hash shorthand
def foo(bar)
  { bar: }
end

# Bare block parameters
def foo(&)
  bar
end

# Pattern matching changes
def foo
  case bar
    in [^(baz)]
    qux = baz
  end
end

def foo
  case bar
    in [^@a, ^$b, ^@@c]
    qux = quuz(@a, @b, @@c)
  end
end
