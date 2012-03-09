require 'simplecov'
SimpleCov.start
require 'minitest/spec'
require 'minitest/autorun'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'ripper_ruby_parser'

def formatted exp
  exp.to_s.gsub /\), /, "),\n"
end
