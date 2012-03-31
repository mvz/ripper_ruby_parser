if ENV["SIMPLECOV"]
  require 'simplecov'
  SimpleCov.start
end
require 'minitest/spec'
require 'minitest/autorun'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'ripper_ruby_parser'

class MiniTest::Spec
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

  def assert_parsed_as sexp, code
    parser = RipperRubyParser::Parser.new
    result = parser.parse code
    assert_equal sexp, result
  end
end

module MiniTest::Expectations
  infect_an_assertion :assert_parsed_as, :must_be_parsed_as
end

