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

  def to_comments exp
    inner = exp.map do |sub_exp|
      if sub_exp.is_a? Sexp
        to_comments sub_exp
      else
        sub_exp
      end
    end

    comments = exp.comments.to_s.gsub(/\n\s*\n/, "\n")
    if comments.empty?
      s(*inner)
    else
      s(:comment, comments, s(*inner))
    end
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

