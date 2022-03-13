# Samples that need Ruby 3.0 or higher

# Right-ward assignment
42 => foo

# Argument forwarding with leading argument
def foo(bar, ...)
  baz bar
  qux(...)
end

# Endless methods
def foo # Avoid comment attaching to next method
end

def foo(bar) = baz(bar)
def foo(bar) = baz(bar) rescue qux
def baz = qux

def bar.baz = qux
