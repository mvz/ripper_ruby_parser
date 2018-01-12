# Change log

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
