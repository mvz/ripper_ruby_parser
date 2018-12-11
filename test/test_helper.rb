require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require 'minitest/autorun'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'ripper_ruby_parser'

module MiniTest
  class Spec
    def formatted(exp)
      exp.to_s.gsub(/\), /, "),\n")
    end

    def fix_lines(exp)
      return s(:lit, :__LINE__) if exp.sexp_type == :lit && exp.line == exp[1]

      inner = exp.map do |sub_exp|
        if sub_exp.is_a? Sexp
          fix_lines sub_exp
        else
          sub_exp
        end
      end

      s(*inner)
    end

    def to_comments(exp)
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

    def assert_parsed_as(sexp, code)
      parser = RipperRubyParser::Parser.new
      result = parser.parse code
      if sexp.nil?
        assert_nil result
      else
        assert_equal sexp, result
        assert_equal sexp.to_s, result.to_s
      end
    end

    def assert_parsed_as_before(code)
      oldparser = RubyParser.new
      newparser = RipperRubyParser::Parser.new
      newparser.extra_compatible = true
      expected = oldparser.parse code.dup
      result = newparser.parse code
      expected = to_comments fix_lines expected
      result = to_comments fix_lines result
      assert_equal formatted(expected), formatted(result)
    end
  end

  module Expectations
    infect_an_assertion :assert_parsed_as, :must_be_parsed_as
    infect_an_assertion :assert_parsed_as_before, :must_be_parsed_as_before, :unary
  end
end
