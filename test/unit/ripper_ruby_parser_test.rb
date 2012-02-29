require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser do
  describe "#parse" do
    it "returns an s-expression" do
      result = RipperRubyParser.new.parse "foo"
      result.must_be_instance_of Sexp
    end
  end
end
