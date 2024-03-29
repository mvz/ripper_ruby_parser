# Changelog

Notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning 2.0.0][1].

This document is formatted based on [Keep A CHANGELOG][2].

## 1.11.0 / 2024-01-05

* Support Ruby 3.0 through 3.3, dropping support for Ruby 2.6 and 2.7
  ([#218], [#219], [#233] and [#246] by [mvz])
* Target compatibility with `ruby_parser` version 3.20.2
  ([#199], [#216] and [#230] by [mvz])
* Support single-line pattern matching ([#188] by [mvz])
* Support rightward assignment ([#189] by [mvz])
* Support endless methods with Ruby 3.0 syntax ([#191] by [mvz])
* Support arguments without parentheses in endless method body ([#193] by [mvz])
* Add support for pattern matching ([#172] by [mvz])
* Add tentative support for numbered parameters ([#163] by [mvz])
* Support several new Ruby 3.1 syntax features ([#196] by [mvz])
* Support negative rational and imaginary literals ([#197] by [mvz])
* Correctly handle match operator with regexp literals in parentheses
  ([#200] by [mvz])
* Improve operator assignment handling ([#201] by [mvz])
* Handle literal Ctrl-? (DEL) character correctly ([#202] by [mvz])
* Handle method names that are keywords in method definitions ([#204] by [mvz])
* Improve dsym handling compatibility ([#203], [#210] by [mvz])
* Add support for Ruby 3.2's splat and kwsplat argument forwarding ([#231] by [mvz])
* Improve handling of the case .. in construction ([#234] by [mvz])

[mvz]: https://github.com/mvz

[#163]: https://github.com/mvz/ripper_ruby_parser/pull/163
[#172]: https://github.com/mvz/ripper_ruby_parser/pull/172
[#188]: https://github.com/mvz/ripper_ruby_parser/pull/188
[#189]: https://github.com/mvz/ripper_ruby_parser/pull/189
[#191]: https://github.com/mvz/ripper_ruby_parser/pull/191
[#193]: https://github.com/mvz/ripper_ruby_parser/pull/193
[#196]: https://github.com/mvz/ripper_ruby_parser/pull/196
[#197]: https://github.com/mvz/ripper_ruby_parser/pull/197
[#199]: https://github.com/mvz/ripper_ruby_parser/pull/199
[#200]: https://github.com/mvz/ripper_ruby_parser/pull/200
[#201]: https://github.com/mvz/ripper_ruby_parser/pull/201
[#202]: https://github.com/mvz/ripper_ruby_parser/pull/202
[#203]: https://github.com/mvz/ripper_ruby_parser/pull/203
[#204]: https://github.com/mvz/ripper_ruby_parser/pull/204
[#205]: https://github.com/mvz/ripper_ruby_parser/pull/205
[#210]: https://github.com/mvz/ripper_ruby_parser/pull/210
[#216]: https://github.com/mvz/ripper_ruby_parser/pull/216
[#218]: https://github.com/mvz/ripper_ruby_parser/pull/218
[#219]: https://github.com/mvz/ripper_ruby_parser/pull/219
[#230]: https://github.com/mvz/ripper_ruby_parser/pull/230
[#231]: https://github.com/mvz/ripper_ruby_parser/pull/231
[#232]: https://github.com/mvz/ripper_ruby_parser/pull/232
[#233]: https://github.com/mvz/ripper_ruby_parser/pull/233
[#234]: https://github.com/mvz/ripper_ruby_parser/pull/234
[#235]: https://github.com/mvz/ripper_ruby_parser/pull/235
[#246]: https://github.com/mvz/ripper_ruby_parser/pull/246

## 1.10.0 / 2022-03-13

* Handle shadow arguments ([#161])
* Drop support for Ruby 2.5 ([#165])
* Support running on Ruby 3.1([#180])

## 1.9.0 / 2021-08-10

* Fix escape sequence handling in non-interpolating strings and word lists
  ([#152])
* Handle strings with mixed valid and invalid utf8 ([#153])
* Handle argument forwarding, updating the RubyParser compatibility target to
  3.17.0 ([#154])
* Fix encoding for non-interpolating strings as well ([#155])

## 1.8.0 / 2021-05-18

### Changes

* Drop support for Ruby 2.4 ([2cf6b4050] and [#145])
* Update RubyParser compatibility target to 3.15.0 ([#105])
* Fix handling of dedented heredoc ([#106])
* Add support for running on Ruby 3.0 ([#123])
* Various code improvements and other internal changes

## 1.7.2 / 2020-02-28

### Bug fixes

* Support imaginary number literals ([#100])
* Handle anonymous kwrest arguments ([#95])

### Internal changes

* Update tests ([#101])
* Prepare for testing on Ruby 2.7 ([#99])
* Various improvements ([#98])
* Split long module ([#97])

## 1.7.1 / 2019-11-03

* Handle unicode escapes with five or six hex digits ([#94])
* Handle safe attribute assignment ([#92])
* Handle endless ranges on Ruby 2.6+ ([#90])
* Add preliminary support for Ruby 2.7 ([#89])
* Improve line number handling for stabby lambdas ([#88])

## 1.7.0 / 2019-11-01

* Make results compatible with RubyParser 3.14.0 ([#85])
  - Remove obsolete extra-compatible behavior
  - Parse stabby lambda as :lambda-typed sexp
  - Emit nil argument for block arguments with trailing comma
* Require Ruby 2.4 or higher ([#86])

## 1.6.1 / 2019-04-22

* Improve line numbering for some block structures ([#82])
  - Fix line numbering for empty method bodies
  - Assign correct line numbers to END blocks
  - Assign correct line numbers to begin blocks
  - Assign correct line numbers to BEGIN blocks
* Fix line numbering for several literals ([#80])
  - Fix line numbering for plain regexp literals
  - Fix line numbering for backtick literals
  - Fix line numbering for simple string literals
  - Fix line numbering for keyword-like symbols

## 1.6.0 / 2019-04-12

* Fix line numbering for range literals ([#79])
* Match handling of carriage returns in heredocs in extra-compatible mode
  ([#77], [#78])
* Match RubyParser behavior for current Ruby rather than latest Ruby ([#76])
  - Adjust integration tests to compare against `RubyParser.for_current_ruby`
  - Remove extra-compatible handling of `rescue` modifier
* Handle directly nested parentheses in destructuring ([#75])
* Make results compatible with RubyParser 3.13.1 ([#74])
  - Remove extra-compatible handling of string literals
* Improve compatibility for when clauses containing `begin..end` blocks ([#73])
* Handle use of backtick as a symbol ([#72])
* Improve string handling compatibility ([#71])
  - Interpolation with `__FILE__` keyword
  - Line continuation after interpolation for indentable heredocs
  - Nested interpolations
* Handle method argument destructuring ([#70])
* Improve compatibility of operator assignment ([#69])
* Handle multiple assignment with RHS that is a block ([#68])
* Improve compatibility of handling escaped line-endings ([#67])
* Make results compatible with RubyParser 3.13.0 ([#65])
  - Change result for `BEGIN { foo }`
  - Remove extra-compatible handling of rescue modifier

## 1.5.1 / 2019-03-21

* Fix handling of singleton methods whose names are keywords
  ([#66])

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

<!-- Pull request links -->
[#180]: https://github.com/mvz/ripper_ruby_parser/pull/180
[#172]: https://github.com/mvz/ripper_ruby_parser/pull/172
[#163]: https://github.com/mvz/ripper_ruby_parser/pull/163
[#165]: https://github.com/mvz/ripper_ruby_parser/pull/165
[#161]: https://github.com/mvz/ripper_ruby_parser/pull/161
[#155]: https://github.com/mvz/ripper_ruby_parser/pull/155
[#154]: https://github.com/mvz/ripper_ruby_parser/pull/154
[#153]: https://github.com/mvz/ripper_ruby_parser/pull/153
[#152]: https://github.com/mvz/ripper_ruby_parser/pull/152
[#145]: https://github.com/mvz/ripper_ruby_parser/pull/145
[#123]: https://github.com/mvz/ripper_ruby_parser/pull/123
[#106]: https://github.com/mvz/ripper_ruby_parser/pull/106
[#105]: https://github.com/mvz/ripper_ruby_parser/pull/105
[#101]: https://github.com/mvz/ripper_ruby_parser/pull/101
[#100]: https://github.com/mvz/ripper_ruby_parser/pull/100
[#99]: https://github.com/mvz/ripper_ruby_parser/pull/99
[#98]: https://github.com/mvz/ripper_ruby_parser/pull/98
[#97]: https://github.com/mvz/ripper_ruby_parser/pull/97
[#95]: https://github.com/mvz/ripper_ruby_parser/pull/95
[#94]: https://github.com/mvz/ripper_ruby_parser/pull/94
[#92]: https://github.com/mvz/ripper_ruby_parser/pull/92
[#90]: https://github.com/mvz/ripper_ruby_parser/pull/90
[#89]: https://github.com/mvz/ripper_ruby_parser/pull/89
[#88]: https://github.com/mvz/ripper_ruby_parser/pull/88
[#86]: https://github.com/mvz/ripper_ruby_parser/pull/86
[#85]: https://github.com/mvz/ripper_ruby_parser/pull/85
[#82]: https://github.com/mvz/ripper_ruby_parser/pull/82
[#80]: https://github.com/mvz/ripper_ruby_parser/pull/80
[#79]: https://github.com/mvz/ripper_ruby_parser/pull/79
[#78]: https://github.com/mvz/ripper_ruby_parser/pull/78
[#77]: https://github.com/mvz/ripper_ruby_parser/pull/77
[#76]: https://github.com/mvz/ripper_ruby_parser/pull/76
[#75]: https://github.com/mvz/ripper_ruby_parser/pull/75
[#74]: https://github.com/mvz/ripper_ruby_parser/pull/74
[#73]: https://github.com/mvz/ripper_ruby_parser/pull/73
[#72]: https://github.com/mvz/ripper_ruby_parser/pull/72
[#71]: https://github.com/mvz/ripper_ruby_parser/pull/71
[#70]: https://github.com/mvz/ripper_ruby_parser/pull/70
[#69]: https://github.com/mvz/ripper_ruby_parser/pull/69
[#68]: https://github.com/mvz/ripper_ruby_parser/pull/68
[#67]: https://github.com/mvz/ripper_ruby_parser/pull/67
[#66]: https://github.com/mvz/ripper_ruby_parser/pull/66
[#65]: https://github.com/mvz/ripper_ruby_parser/pull/65

<!-- Git sha links -->
[2cf6b4050]: https://github.com/mvz/ripper_ruby_parser/commit/2cf6b40501576003b916196e23222276b51aa53c

<!-- Other links -->

[1]:  https://semver.org/spec/v2.0.0.html
[2]:  https://keepachangelog.com/en/1.0.0/
