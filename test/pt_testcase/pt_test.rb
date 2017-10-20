require File.expand_path('../test_helper.rb', File.dirname(__FILE__))
require 'pt_testcase'

class TestParser < RipperRubyParser::Parser
  def process(input)
    parse input
  end
end

SKIPPED_TESTS = ['dstr_heredoc_windoze_sucks'].freeze

class RubyParserTestCase < ParseTreeTestCase
  def self.previous(_key)
    'Ruby'
  end

  def self.generate_test(klass, node, data, input_name, _output_name)
    if data['Ruby'].is_a? Array
      klass.send :define_method, "test_#{node}" do
        skip 'Not a parser test'
      end
      return
    end

    if SKIPPED_TESTS.include? node
      klass.send :define_method, "test_#{node}" do
        skip "Can't or won't fix this difference"
      end
      return
    end

    super klass, node, data, input_name, 'ParseTree'
  end
end

class TestRuby19Parser < RubyParserTestCase
  def setup
    super

    self.processor = TestParser.new
  end
end
