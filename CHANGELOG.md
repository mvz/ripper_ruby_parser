# Changelog

## 1.5.1 / 2019-03-21

* Fix handling of singleton methods whose names are keywords
  ([#66](https://github.com/mvz/ripper_ruby_parser/pull/66))

## 1.5.0 / 2019-03-18

* Process embedded documents as comments
* Handle \u{xxxx} form of unicode escape sequence
* Treat keyword rest arguments (double spats) as local variables, for blocks
  and for methods.
  Versions of Ripper before CRuby 2.6 do not handle these correctly, so
  RipperRubyParser adds its own accounting of these parameters.
* Do not unescape heredocs with single quotes. These are heredocs where the
  marker is a single-quoted string
* Increase compatibility when handling a begin..end block, e.g., as an assigned
  value, as a receiver, as a condition
* Fix handling of for loops that assign to multiple loop variables
* Handle aliasing for method names that are keywords, e.g., `alias next succ`
* Do not crash on rational literals
* Restore `#extra_compatible` flag
* Match RubyParser bug in handling rescue modifier when combined with
  assignment. See RubyParser
  [issue #227](https://github.com/seattlerb/ruby_parser/issues/227).
  This behavior is only enabled when `#extra_compatible` is set to true
* Fix compatibility when assigning to a class variable inside the method
  argument specification
* Match RubyParser's handling of byte sequences in second and further literal
  parts of strings with interpolations. This behavior is only enabled when
  `#extra_compatible` is set to true
* Require Ruby 2.3 or higher
* Mark as compatible with RubyParser 3.12.0
* Match RubyParser's handling of block keyword rest arguments.
  This behavior is only enabled when `#extra_compatible` is set to true
* Support Ruby 2.6

## 1.4.2 / 2018-04-03

* Fix handling of strings delimited by %()
* Handle line continuations in stringlike literals
  - Handle line continuations in string and regexp literals
  - Handle escaped line continuations
  - Handle line continuations in word and symbol list literals
* Force encoding of string literals to UTF-8 if the result is valid
* Fix handling of range operators with float literals

## 1.4.1 / 2018-03-31

* Properly pop delimiter stack after parsing a symbol

## 1.4.0 / 2018-03-30

* Handle begin..end blocks with postfix conditionals
* Match RubyParser's handling of string literals that do not allow escape
  sequences

## 1.3.0 / 2018-02-17

* Change result for `self[:foo]` to match RubyParser 3.11.0.

## 1.2.0 / 2018-01-12

* Improve code quality
* Document public API
* Speed improvements
  - Process line numbers only once per parse run
  - Reduce arbitrary conditionals
  - Use deconstruction to split up block
* Improve intermediate s-expressions, reducing the number of typeless
  expressions.
* Use SexpBuilder base class, giving more low-level access to the structure
  created by Ripper.
* Support Ruby 2.5
* Improve handling of boolean operators with parenthes
* Improve compatibility for begin..end blocks used as method and operator
  arguments.
* Support Ruby 2.5
* Drop support for Ruby 2.0 and 2.1
* Handle `__ENCODING__` constant.

## 1.1.2 / 2017-10-07

* Fix support for newer Ruby syntax
  - Handle optional keyword arguments
  - Handle mandatory keyword arguments (Ruby 2.1 and up)
  - Handle double splat arguments in function definitions
  - Handle double splat in hash literals and method calls
  - Handle symbol arrays with %i and %I
  - Handle use of dynamic symbols as hash keys (Ruby 2.2 and up)
  - Handle safe call operator (Ruby 2.3 and up)
* Other bug fixes
  - Fix handling of return and yield with a function call without parentheses
  - Handle stabby lambdas with any number of statements
  - Handle more complex interpolation in %W word arrays
  - Distinguish unary minus from negative sign for int and float literals
* Compatibility improvements
  - Match RubyParser's rewriting of conditionals with the negative match
    operator

## 1.1.1 / 2017-10-03

* Fix handling of non-final splats in LHS

## 1.1.0 / 2017-10-02

* Compatible with RubyParser 3.10.x
* Add support for Ruby 2.2, 2.3 and 2.4
* Drop support for Ruby 1.9.3

## 1.0.0 / 2014-02-07

* First major release
* Compatible with RubyParser 3.3.x

## 0.0.8 / 2012-06-22

## 0.0.7 / 2012-06-08

## 0.0.6 / 2012-04-04

## 0.0.5 / 2012-04-02

## 0.0.4 / 2012-03-31

## 0.0.3 / 2012-03-21

## 0.0.2 / 2012-03-19

## 0.0.1 / 2012-03-11

* Initial release
