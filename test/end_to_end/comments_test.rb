require File.expand_path('../test_helper.rb', File.dirname(__FILE__))
require 'ruby_parser'

describe "Comment results for RipperRubyParser and RubyParser" do
  def to_comments exp
    inner = exp.map do |sub_exp|
      if sub_exp.is_a? Sexp
        to_comments sub_exp
      else
        sub_exp
      end
    end

    if exp.comments.nil?
      s(*inner)
    else
      s(:comment, exp.comments, s(*inner))
    end
  end

  let :newparser do
    RipperRubyParser::Parser.new
  end

  let :oldparser do
    RubyParser.new
  end

  describe "for a program with quite some comments" do
    let :program do
      <<-END
      # Foo
      class Foo
        # The foo
        # method
        def foo
          bar # bar
          # internal comment
        end

        def bar
          baz
        end
      end
      # Quux
      module Qux
        class Quux
          def bar
          end
          def baz
          end
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
      to_comments(imitation).must_equal to_comments(original)
    end
  end
end
