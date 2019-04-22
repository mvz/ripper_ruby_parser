# RipperRubyParser

by Matijs van Zuijlen

## Description

Parse with Ripper, produce sexps that are compatible with RubyParser.

## Features/Notes

* Drop-in replacement for RubyParser
* Should handle 1.9 and later syntax gracefully
* Requires MRI 2.3 or higher
* Compatible with RubyParser 3.13.1

## Known incompatibilities

RipperRubyParser has some incompatibilities with RubyParser. For some of these,
the behavior can be changed by turning on extra-compatible mode.

The following incompatibilities cannot be changed:

* RipperRubyParser won't handle non-UTF-8 files without an encoding comment,
  just like regular Ruby
* RipperRubyParser does not match RubyParser's line numbering
* RipperRubyParser correctly dedents heredocs with interpolations

The following incompatibilities can be made compatible by turning on
extra-compatible mode:

* Operator assignment of a method call without parentheses to a collection
  element uses an `:array` S-expression instead of `:arglist`
* RipperRubyParser keeps carriage return characters in heredocs that include
  them

## Install

    gem install ripper_ruby_parser

## Synopsis

```ruby
require 'ripper_ruby_parser'

parser = RipperRubyParser::Parser.new
parser.parse "puts 'Hello World'"
# => s(:call, nil, :puts, s(:str, "Hello World!"))
parser.parse "foo[bar] += baz qux"
# => s(:op_asgn1, s(:call, nil, :foo),
#      s(:arglist, s(:call, nil, :bar)),
#      :+,
#      s(:call, nil, :baz, s(:call, nil, :qux)))
parser.extra_compatible = true

parser.parse "foo[bar] += baz qux"
# => s(:op_asgn1, s(:call, nil, :foo),
#      s(:array, s(:call, nil, :bar)),
#      :+,
#      s(:call, nil, :baz, s(:call, nil, :qux)))
```

## Requirements

* Ruby 2.3 or higher
* `sexp_processor`

## Hacking and contributing

If you want to send pull requests or patches, please:

* Make sure `rake test` runs without reporting any failures. If your code
  breaks existing stuff, it won't get merged in.
* Add tests for your feature. Otherwise, I can't see if it works or if I
  break it later.
* Make sure latest master merges cleanly with your branch. Things might
  have moved around since you forked.
* Try not to include changes that are irrelevant to your feature in the
  same commit.

## License

(The MIT License)

Copyright (c) 2012, 2014-2019 Matijs van Zuijlen

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
