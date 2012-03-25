require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe "Using RipperRubyParser" do
  let :newparser do
    RipperRubyParser::Parser.new
  end

  it "raises an error for an incomplete source" do
    proc {
      newparser.parse "def foo"
    }.must_raise RuntimeError
  end
end


