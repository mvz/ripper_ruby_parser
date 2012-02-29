require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    it "returns an s-expression" do
      result = RipperRubyParser::Parser.new.parse "foo"
      result.must_be_instance_of Sexp
    end

    it "post-processes its result with the passed sexp processor" do
      sexp_p = MiniTest::Mock.new
      sexp_p.expect :process, s(:result), [Sexp]

      parser = RipperRubyParser::Parser.new sexp_p
      result = parser.parse "any code"

      result.must_equal s(:result)
      sexp_p.verify
    end
  end
end
