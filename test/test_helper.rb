if ENV["SIMPLECOV"]
  require 'simplecov'
  SimpleCov.start
end
require 'minitest/spec'
require 'minitest/autorun'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'ripper_ruby_parser'

class MiniTest::Unit::TestCase
  def formatted exp
    exp.to_s.gsub(/\), /, "),\n")
  end

  def suppress_warnings
    old_verbose = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = old_verbose
    result
  end
end
