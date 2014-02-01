begin
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test/"
  end
rescue LoadError
end

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

  def assert_parsed_as_before code
    oldparser = RubyParser.new
    newparser = RipperRubyParser::Parser.new
    expected = oldparser.parse code.dup
    result = newparser.parse code
    assert_equal formatted(expected), formatted(result)
  end
end

module MiniTest::Expectations
  infect_an_assertion :assert_parsed_as, :must_be_parsed_as
  infect_an_assertion :assert_parsed_as_before, :must_be_parsed_as_before, :unary
end

