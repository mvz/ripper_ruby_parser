require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for block parameters" do
      specify do
        "foo do |(bar, baz)| end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:masgn,
                                s(:array,
                                  s(:lasgn, :bar),
                                  s(:lasgn, :baz))))
      end

      specify do
        "foo do |(bar, *baz)| end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:masgn,
                                s(:array,
                                  s(:lasgn, :bar),
                                  s(:splat, s(:lasgn, :baz)))))
      end

      specify do
        "foo do |bar,*| end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:masgn, s(:array, s(:lasgn, :bar), s(:splat))))
      end

      specify do
        "foo do |bar, &baz| end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:masgn,
                                s(:array,
                                  s(:lasgn, :bar),
                                  s(:lasgn, :"&baz"))))
      end

      it "behaves differently from RubyParser with a trailing comma in the block parameters" do
        "foo do |bar, | end".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :foo),
                              s(:lasgn, :bar))
      end
    end

    describe "for rescue/else/ensure" do
      it "works for a block with multiple rescue statements" do
        "begin foo; rescue; bar; rescue; baz; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :bar)),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :baz)))
      end

      it "works for a block with rescue and else" do
        "begin; foo; rescue; bar; else; baz; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array),
                                s(:call, nil, :bar)),
                              s(:call, nil, :baz))
      end

      it "works for a block with only else" do
        "begin; foo; else; bar; end".
          must_be_parsed_as s(:block,
                              s(:call, nil, :foo),
                              s(:call, nil, :bar))
      end
    end

    describe "for rescue" do
      it "works with assignment to an error variable" do
        "begin; foo; rescue => bar; baz; end".
          must_be_parsed_as s(:rescue,
                              s(:call, nil, :foo),
                              s(:resbody,
                                s(:array,
                                  s(:lasgn, :bar, s(:gvar, :$!))),
                                s(:call, nil, :baz)))
      end
    end

    describe "for stabby lambda" do
      it "works in the simple case" do
        "->(foo) { bar }".
          must_be_parsed_as s(:iter,
                              s(:call, nil, :lambda),
                              s(:lasgn, :foo),
                              s(:call, nil, :bar)) 
      end
    end
  end
end
