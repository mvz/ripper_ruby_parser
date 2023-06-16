# Blocks

# Block parameters
foo do |bar| end
foo do |bar, | end
foo do |bar, **| end
foo do |(bar, baz)| end
foo do |bar; baz| end
foo do |bar, baz; qux| end
foo do |bar, baz; qux, quuz| end

# Numbered block parameters
# NOTE: Not yet implemented in ruby_parser
# foos.each do _1.bar; end
# foos.each { _1.bar }
