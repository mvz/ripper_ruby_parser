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

  Dir.glob("lib/**/*.rb").each do |file|
    describe "for #{file}" do
      let :program do
        File.read file
      end

      it "gives the same result" do
        original = oldparser.parse program
        imitation = newparser.parse program

        _(formatted(imitation)).must_equal formatted(original)
      end
    end
  end
end
