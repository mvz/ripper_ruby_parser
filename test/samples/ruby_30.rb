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

# Endless methods
def foo # FIXME: Avoid comment attaching to next method
end

def foo(bar) = baz(bar)
def foo(bar) = baz(bar) rescue qux
def baz = qux

def bar.baz = qux
