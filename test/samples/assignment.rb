# Samples of assignment
foo[bar] = baz
foo[bar] += baz
foo[bar] += baz qux
foo[bar] += baz(qux)
foo[bar] += baz.qux quuz
foo[bar] += baz.qux(quuz)
foo[bar] ||= baz
foo[bar] ||= baz qux
foo[bar] ||= baz(qux)
foo[bar] ||= baz.qux quuz
foo[bar] ||= baz.qux(quuz)

foo.bar = baz
foo.bar += baz
# foo.bar += baz qux
foo.bar += baz(qux)
# foo.bar += baz.qux quuz
foo.bar += baz.qux(quuz)
foo.bar ||= baz
# foo.bar ||= baz qux
foo.bar ||= baz(qux)
# foo.bar ||= baz.qux quuz
foo.bar ||= baz.qux(quuz)

# Destructuring assignments
foo, bar = baz
(foo, bar) = baz
((foo, bar)) = baz
(((foo, bar))) = baz
foo, (bar, baz) = qux
foo, ((bar, baz)) = qux
foo, (((bar, baz))) = qux
foo, (bar, (baz, qux)) = quuz

# Safe attribute assignment
foo&.bar = baz
foo[bar]&.baz = qux
foo[bar, baz]&.qux = quuz

# Assignment with too many parentheses on the RHS
foo = ((bar)) - 1
