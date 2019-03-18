# RipperRubyParser

by Matijs van Zuijlen

## Description

Parse with Ripper, produce sexps that are compatible with RubyParser.

## Features/Notes

* Drop-in replacement for RubyParser
* Should handle 1.9 and later syntax gracefully
* Requires MRI 2.3 or higher
* Compatible with RubyParser 3.12.0

## Known incompatibilities

RipperRubyParser has some incompatibilities with RubyParser. For some of these,
the behavior can be changed by turning on extra-compatible mode.

The following incompatibilities cannot be changed:

* RipperRubyParser won't handle non-UTF-8 files without an encoding comment,
  just like regular Ruby
* RipperRubyParser keeps carriage return characters in heredocs that include them
* RipperRubyParser does not attempt to match RubyParser's line numbering bugs

The following incompatibilities can be made compatible by turning on
extra-compatible mode:

* RipperRubyParser handles unicode escapes without braces correctly, while
  RubyParser absorbs trailing hexadecimal characters
* RipperRubyParser handles the rescue modifier correctly, while RubyParser
  still contains a bug that was fixed in Ruby 2.4. See RubyParser
  [issue #227](https://github.com/seattlerb/ruby_parser/issues/227).
* RubyParser handles byte sequences in second and further literal parts of a
  strings with interpolations differently. RipperRubyParser will convert these
  to unicode if possible.
* RubyParser handles byte sequences in heredocs and interpolating word lists
  differently. RipperRubyParser will convert these to unicode if possible.

## Install

    gem install ripper_ruby_parser

## Synopsis

    require 'ripper_ruby_parser'

    parser = RipperRubyParser::Parser.new
    parser.parse "puts 'Hello World'"
    # => s(:call, nil, :puts, s(:arglist, s(:str, "Hello World!")))

    parser.parse '"foo\u273bbar"'
    # => s(:str, "foo✻bar")

    parser.extra_compatible = true

    parser.parse '"foo\u273bbar"'
    # => s(:str, "foo✻r")

## Requirements

* Ruby 2.2 or higher
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

Copyright (c) 2012, 2014-2018 Matijs van Zuijlen

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
