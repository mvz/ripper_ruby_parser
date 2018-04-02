# Miscellaneous samples

# regular expressions with different encoding flags
regular = /foo/
noenc = /foo/n
utf8 = /foo/u
euc = /foo/e
sjis = /foo/s

bar = 'bar'
regular = /foo#{bar}/
noenc = /foo#{bar}/n
utf8 = /foo#{bar}/u
euc = /foo#{bar}/e
sjis = /foo#{bar}/s

# Use of __ENCODING__
enc = __ENCODING__

class Foo
# calling #[] on self
# https://github.com/seattlerb/ruby_parser/issues/250
  def bar
    self[:foo]
  end

# required keyword arguments and no parentheses
# https://github.com/seattlerb/ruby_parser/pull/254
  def foo a:, b:
    puts "A: #{a}, B: #{b}"
  end

# Combinations of begin..end and diverse operators
  def qux
    begin end
    begin; foo; end
    begin; foo; bar; end
    - begin; foo; end
    begin; bar; end + foo
    foo + begin; bar; end
    begin; foo; end ? bar : baz
    foo ? begin; bar; end : baz
    foo ? bar : begin; baz; end
    begin; bar; end and foo
    foo and begin; bar; end
    begin; foo; end if bar
    begin; foo; end unless bar
  end
end
