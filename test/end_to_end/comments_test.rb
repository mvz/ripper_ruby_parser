# frozen_string_literal: true

require File.expand_path("../test_helper.rb", File.dirname(__FILE__))
require "ruby_parser"

describe "Using RipperRubyParser and RubyParser" do
  let :newparser do
    RipperRubyParser::Parser.new
  end

  let :oldparser do
    RubyParser.for_current_ruby
  end

  describe "for a program with quite some comments" do
    let :program do
      <<-RUBY
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
      RUBY
    end

    let :original do
      oldparser.parse program
    end

    let :imitation do
      newparser.parse program
    end

    it "gives the same result" do
      _(imitation).must_equal original
    end

    it "gives the same result with comments" do
      _(to_comments(imitation)).must_equal to_comments(original)
    end
  end
end
