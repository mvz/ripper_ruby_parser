# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/test/"
end

require "minitest/autorun"
require "minitest/focus"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "ripper_ruby_parser"

module MiniTest
  class Spec
    def inspect_with_line_numbers(exp)
      parts = exp.map do |sub_exp|
        if sub_exp.is_a? Sexp
          inspect_with_line_numbers(sub_exp)
        else
          sub_exp.inspect
        end
      end

      plain = "s(#{parts.join(", ")})"
      if exp.line
        "#{plain}.line(#{exp.line})"
      else
        plain
      end
    end

    def formatted(exp, with_line_numbers: false)
      inspection = if with_line_numbers
                     inspect_with_line_numbers(exp)
                   else
                     exp.inspect
                   end
      inspection.gsub("), ", "),\n")
    end

    def fix_lines(exp)
      if exp.sexp_type == :lit && exp.line == exp[1]
        return s(:lit, :__LINE__).line(exp.line)
      end

      exp.sexp_body = exp.sexp_body.map do |sub_exp|
        if sub_exp.is_a? Sexp
          fix_lines sub_exp
        else
          sub_exp
        end
      end

      exp
    end

    def to_comments(exp)
      comments = exp.comments.to_s.gsub(/\n\s*\n/, "\n")

      exp.sexp_body = exp.sexp_body.map do |sub_exp|
        if sub_exp.is_a? Sexp
          to_comments sub_exp
        else
          sub_exp
        end
      end

      if comments.empty?
        exp
      else
        s(:comment, comments, exp)
      end
    end

    def assert_parsed_as(sexp, code, with_line_numbers: false)
      parser = RipperRubyParser::Parser.new
      result = parser.parse code
      if sexp.nil?
        assert_nil result
      else
        assert_equal sexp, result
        assert_equal(formatted(sexp, with_line_numbers: with_line_numbers),
                     formatted(result, with_line_numbers: with_line_numbers))
      end
    end

    def assert_parsed_as_before(code, with_line_numbers: false)
      oldparser = RubyParser.for_current_ruby
      newparser = RipperRubyParser::Parser.new
      newparser.extra_compatible = true
      expected = oldparser.parse code.dup
      result = newparser.parse code
      expected = to_comments fix_lines expected
      result = to_comments fix_lines result

      assert_equal expected, result
      assert_equal(formatted(expected, with_line_numbers: with_line_numbers),
                   formatted(result, with_line_numbers: with_line_numbers))
    end
  end

  Expectation.class_eval do
    def must_be_parsed_as(sexp, with_line_numbers: false)
      ctx.assert_parsed_as(sexp, target, with_line_numbers: with_line_numbers)
    end

    def must_be_parsed_as_before(with_line_numbers: false)
      ctx.assert_parsed_as_before(target, with_line_numbers: with_line_numbers)
    end
  end
end
