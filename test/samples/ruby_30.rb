# Samples that need Ruby 3.0 or higher

# Right-ward assignment
def foo
  42 => bar
end

# Argument forwarding with leading argument
def foo(bar, ...)
  baz bar
  qux(...)
end

# Argument forwarding with leading argument in call
def foo(...)
  bar(...)
  bar(qux, ...)
end

# New pattern matching options
case foo
in [*, :baz3, qux, *]
end

# Endless methods
def foo(bar) = baz(bar)
def foo(bar) = baz(bar) rescue qux
def baz = qux

def bar.baz = qux
