require File.expand_path('../test_helper.rb', File.dirname(__FILE__))
require 'ruby_parser'

describe "Using RipperRubyParser and RubyParser" do
  let :newparser do
    RipperRubyParser::Parser.new
  end

  let :oldparser do
    RubyParser.new
  end

  describe "for a simple well known program" do
    let :program do
      "puts 'Hello World'"
    end

    it "gives the same result" do
      original = oldparser.parse program
      imitation = newparser.parse program

      imitation.must_equal original
    end
  end

  describe "for a more complex program" do
    let :program do
      <<-END
      module Quux
        class Foo
          def bar
            baz = 3
            qux baz
          end
          def qux it
            if it == 3
              [1,2,3].map {|i| 2*i}
            end
          end
        end
      end

      Quux::Foo.new.bar
      END
    end

    it "gives the same result" do
      original = oldparser.parse program
      imitation = newparser.parse program

      imitation.must_equal original
    end
  end

end

