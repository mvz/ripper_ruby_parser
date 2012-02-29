require File.expand_path('../test_helper.rb', File.dirname(__FILE__))
require 'ruby_parser'

describe "Using RipperRubyParser and RubyParser" do
  let :newparser do
    RipperRubyParser.new
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
end

