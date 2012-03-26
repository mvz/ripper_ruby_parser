require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe "Handling errors" do
  describe "RipperRubyParser::Parser#parse" do
    let :newparser do
      RipperRubyParser::Parser.new
    end

    it "raises an error for an incomplete source" do
      proc {
        newparser.parse "def foo"
      }.must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error for an invalid class name" do
      proc {
        newparser.parse("class foo; end")
      }.must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error aliasing $1 as foo" do
      proc {
        newparser.parse "alias foo $1"
      }.must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error aliasing foo as $1" do
      proc {
        newparser.parse "alias $1 foo"
      }.must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error aliasing $2 as $1" do
      proc {
        newparser.parse "alias $1 $2"
      }.must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error assigning to $1" do
      proc {
        newparser.parse "$1 = foo"
      }.must_raise RipperRubyParser::SyntaxError
    end

    it "raises an error using an invalid parameter name" do
      proc {
        newparser.parse "def foo(BAR); end"
      }.must_raise RipperRubyParser::SyntaxError
    end
  end
end
