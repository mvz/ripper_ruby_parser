require File.expand_path('../test_helper.rb', File.dirname(__FILE__))
require 'ruby_parser'

describe "Using RipperRubyParser and RubyParser" do
  def to_line_numbers exp
    inner = exp.map do |sub_exp|
      if sub_exp.is_a? Sexp
        to_line_numbers sub_exp
      else
        sub_exp
      end
    end

    if exp.line.nil?
      s(*inner)
    else
      s(:line_number, exp.line, s(*inner))
    end
  end

  let :newparser do
    RipperRubyParser::Parser.new
  end

  let :oldparser do
    RubyParser.new
  end

  describe "for a multi-line program" do
    let :program do
      <<-END
      class Foo
        def foo
          bar()
          baz(qux)
        end
      end
      END
    end

    let :original do
      oldparser.parse program
    end

    let :imitation do
      newparser.parse program
    end

    it "gives the same result" do
      imitation.must_equal original
    end

    it "gives the same result with comments" do
      formatted(to_line_numbers(imitation)).
        must_equal formatted(to_line_numbers(original))
    end
  end
end

