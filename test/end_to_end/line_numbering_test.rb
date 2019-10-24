# frozen_string_literal: true

require File.expand_path("../test_helper.rb", File.dirname(__FILE__))
require "ruby_parser"

describe "Using RipperRubyParser and RubyParser" do
  describe "for a multi-line program" do
    let :program do
      <<-RUBY
      class Foo
        def foo()
          bar()
          baz(qux)
        end
      end

      module Bar
        @@baz = {}
      end
      RUBY
    end

    it "gives the same result" do
      _(program).must_be_parsed_as_before
    end

    it "gives the same result with line numbers" do
      _(program).must_be_parsed_as_before with_line_numbers: true
    end
  end
end
