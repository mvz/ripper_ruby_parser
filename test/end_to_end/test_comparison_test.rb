# frozen_string_literal: true

require File.expand_path("../test_helper.rb", File.dirname(__FILE__))
require "ruby_parser"

describe "Using RipperRubyParser and RubyParser" do
  Dir.glob("test/ripper_ruby_parser/**/*.rb").each do |file|
    describe "for #{file}" do
      let :program do
        File.read file
      end

      it "gives the same result" do
        _(program).must_be_parsed_as_before
      end
    end
  end
end
