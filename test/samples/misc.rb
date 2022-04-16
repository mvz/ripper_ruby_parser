# Miscellaneous samples

BEGIN {
  begin
    foo
  end
}

BEGIN {}

END {
  begin
    bar
  end
}

END {}

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
    begin; foo; end.bar
    foo ||= begin; bar; end
    foo += begin; bar; end
    foo[qux] ||= begin; bar; end
    foo = begin; bar; end
    foo = begin; if bar; baz; end; end
    baz = begin; foo; ensure; bar; end
    foo = *begin; bar; end
    foo = bar, *begin; baz; end
    foo, bar = *begin; baz; end
    foo if begin bar end
  end

  # Nested do and begin blocks
  def quuz
    foo do
      bar

      begin
        baz
      rescue
        qux
      end

      quuz
    end
  end

  # Nested begin/rescue blocks
  def quuz
    begin
      bar
    rescue
      begin
        baz
      end
    end

    begin
      bar
    rescue
      begin
        baz
      rescue
        qux
      end
    end

    begin
      bar
    rescue
      begin
        baz
      end
      begin
        qux
      end
    end
  end

  # Begin/end blocks and case statements
  def quuz
    case foo
    when bar
      begin
        baz
      end
    end

    case foo
    when bar
      begin
        baz
        qux
      end
    end

    case foo
    when bar
      begin
        baz
        qux
      end
      quuz
    end

    case foo
    when bar
    else
      begin
        baz
        qux
      end
    end

    case foo
    when bar
    else
      begin
        baz
        qux
      end
      quuz
    end
  end

  # Using splat and double-splat args
  def barbaz(*foo, **bar)
    puts [foo, bar]
    foo.each do |baz, **qux|
      puts [foo, bar, baz, qux]
    end
    puts [foo, bar]
  end

  def barbaz_block(*foo, **bar, &block)
    puts [foo, bar]
  end

  def self.barbaz(*foo, **bar)
    puts [foo, bar]
    foo.each do |baz, **qux|
      puts [foo, bar, baz, qux]
    end
    puts [foo, bar]
  end

  def foobarbaz(**)
  end

  # rescue
  def barfoo
    foo
  rescue *bar
    baz
  rescue *quuz, Bar
    zyxxy
  rescue *qux => err
    puts err
  end

  # begin/rescue with multiple assignment
  foo, bar = begin
    baz
  rescue qux
    quuz
  end

  # alias
  alias foo bar
  alias :foo bar
  alias :foo :bar
  alias foo :bar
  alias :+ -
  alias next bar

  # rescue with assignment
  foo = bar rescue baz
  foo = bar baz rescue qux
  foo = bar(baz) rescue qux
  foo, bar = baz qux rescue quuz
  @foo = bar baz rescue qux
  @@foo = bar baz rescue qux
  FOO = bar baz rescue qux
  $foo = bar baz rescue qux
  foo = Foo.bar(baz) rescue qux
  foo = Foo.bar baz rescue qux

  # Assignment to class variables inside method argument
  # definitions.
  def foo(bar = (@@baz = qux))
  end

  def self.foo(bar = (@@baz = qux))
  end

  def (bar = (@@baz = qux)).foo
  end

  # Assignment to global variables inside method argument
  # definitions.
  def foo(bar = ($baz = qux))
  end

  # Argument destructuring
  def foo((bar, baz))
  end

  def foo((bar, baz), (qux, quuz))
  end

  def foo((bar, *qux))
  end

  def foo((bar, (baz, qux)))
  end

  def foo((bar, (baz, *qux)))
  end

  def self.foo((bar, baz))
  end

  def self.foo((bar, baz), (qux, quuz))
  end

  def self.foo((bar, *qux))
  end

  def self.foo((bar, (baz, qux)))
  end

  def self.foo((bar, (baz, *qux)))
  end
end

# Special symbols
[:`, :|, :*, :&, :%, :'^', :-@, :+@, :'~@']

# Non-ascii symbols
[:cosí, :😎]

class Foö
  def bär
    "Röär!"
  end
end

# Blocks
foo do |bar| end
foo do |bar, | end
foo do |bar, **| end
foo do |(bar, baz)| end
foo do |bar; baz| end
foo do |bar, baz; qux| end
foo do |bar, baz; qux, quuz| end

# defined? keyword
if defined? foo
  bar
end

# Methods with names that are also keywords
class Bar
  # Command A
  def begin
    foo.end.begin
  end

  # Command B
  def class
    "Woof!"
  end
end

# Endless ranges
1..

foobar = 2
foobar..
