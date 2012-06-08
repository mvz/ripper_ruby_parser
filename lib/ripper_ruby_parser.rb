if RUBY_VERSION < "1.9.3"
  raise LoadError, "Only ruby version 1.9.3 and up are supported"
end

require 'ripper_ruby_parser/version'
require 'ripper_ruby_parser/parser'

module RipperRubyParser
end
