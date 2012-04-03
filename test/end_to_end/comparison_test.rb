require File.expand_path('../test_helper.rb', File.dirname(__FILE__))
require 'ruby_parser'

describe "Using RipperRubyParser and RubyParser" do
  let :newparser do
    RipperRubyParser::Parser.new
  end

  let :oldparser do
    RubyParser.new
  end

  describe "for a simple well known program" do
    let :program do
      "puts 'Hello World'"
    end

    it "gives the same result" do
      original = oldparser.parse program
      imitation = newparser.parse program

      imitation.must_equal original
    end
  end

  describe "for a more complex program" do
    let :program do
      <<-END
      module Quux
        class Foo
          def bar
            baz = 3
            qux baz
          end
          def qux it
            if it == 3
              [1,2,3].map {|i| 2*i}
            end
          end
        end
      end

      Quux::Foo.new.bar
      END
    end

    it "gives the same result" do
      original = oldparser.parse program
      imitation = newparser.parse program

      imitation.must_equal original
    end
  end

  describe "for an example with yield from Reek" do
    let :program do
      'def fred() yield(3) if block_given?; end'
    end

    it "gives the same result" do
      original = oldparser.parse program
      imitation = newparser.parse program

      imitation.must_equal original
    end
  end

  describe "for an example with floats from Reek" do
    let :program do
      <<-END
        def total_envy
          fred = @item
          total = 0
          total += fred.price
          total += fred.tax
          total *= 1.15
        end
      END
    end

    it "gives the same result" do
      original = oldparser.parse program
      imitation = newparser.parse program

      formatted(imitation).must_equal formatted(original)
    end
  end

  describe "for an example with operators and explicit block parameter from Reek" do
    let :program do
      <<-END
        def parse(arg, argv, &error)
          if !(val = arg) and (argv.empty? or /\\A-/ =~ (val = argv[0]))
            return nil, block, nil
          end
          opt = (val = parse_arg(val, &error))[1]
          val = conv_arg(*val)
          if opt and !arg
            argv.shift
          else
            val[0] = nil
          end
          val
        end
      END
    end

    it "gives the same result" do
      original = oldparser.parse program
      imitation = newparser.parse program

      formatted(imitation).must_equal formatted(original)
    end
  end

  describe "for an example of a complex regular expression from Reek" do
    let :program do
      "/(\#{@types})\\s*(\\w+)\\s*\\(([^)]*)\\)/"
    end

    it "gives the same result" do
      original = oldparser.parse program
      imitation = newparser.parse program

      formatted(imitation).must_equal formatted(original)
    end
  end

  describe "for an example with regular expressions with different encoding flags" do
    it "gives the same result" do
      program = <<-END
        regular = /foo/
        noenc = /foo/n
        utf8 = /foo/u
        euc = /foo/e
        sjis = /foo/s

        regular = /foo\#{bar}/
        noenc = /foo\#{bar}/n
        utf8 = /foo\#{bar}/u
        euc = /foo\#{bar}/e
        sjis = /foo\#{bar}/s
      END

      program.must_be_parsed_as_before
    end
  end
end

