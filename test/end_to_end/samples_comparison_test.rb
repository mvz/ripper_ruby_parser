require File.expand_path('../test_helper.rb', File.dirname(__FILE__))
require 'ruby_parser'

describe "Using RipperRubyParser and RubyParser" do
  let :newparser do
    RipperRubyParser::Parser.new
  end

  let :oldparser do
    RubyParser.new
  end

  Dir.glob("samples/**/*.rb").each do |file|
    describe "for #{file}" do
      let :program do
        File.read file
      end

      let :original do
        oldparser.parse program
      end

      let :imitation do
        newparser.extra_compatible = true
        newparser.parse program
      end

      it "gives the same result" do
        formatted(imitation).must_equal formatted(original)
      end

      it "gives the same result with comments" do
        formatted(to_comments(imitation)).
          must_equal formatted(to_comments(original))
      end
    end
  end
end
