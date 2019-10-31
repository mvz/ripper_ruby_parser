# frozen_string_literal: true

describe RipperRubyParser do
  it "knows its own version" do
    _(RipperRubyParser::VERSION).wont_be_nil
  end
end
