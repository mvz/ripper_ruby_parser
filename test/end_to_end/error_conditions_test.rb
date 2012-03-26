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

    it "raises an error for an invalid alias" do
      proc {
        newparser.parse "alias foo $1"
      }.must_raise RipperRubyParser::SyntaxError
    end
  end
end
