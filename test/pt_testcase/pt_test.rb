require File.expand_path('../test_helper.rb', File.dirname(__FILE__))
require 'pt_testcase'

class RipperRubyParser::Parser
  def process input
    parse input
  end
end

class RubyParserTestCase < ParseTreeTestCase
  def self.previous key
    "Ruby"
  end

  def self.generate_test klass, node, data, input_name, output_name
    return if Array === data['Ruby']

    output_name = "ParseTree"

    super
  end
end

class TestRuby19Parser < RubyParserTestCase
  def setup
    super

    self.processor = RipperRubyParser::Parser.new
  end
end
