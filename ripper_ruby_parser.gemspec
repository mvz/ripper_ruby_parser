# -*- encoding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'lib/ripper_ruby_parser/version.rb')

Gem::Specification.new do |s|
  s.name = "ripper_ruby_parser"
  s.version = RipperRubyParser::VERSION

  s.summary = "Parse with Ripper, produce sexps that are compatible with RubyParser."

  s.authors = ["Matijs van Zuijlen"]
  s.email = ["matijs@matijs.net"]
  s.homepage = "http://www.github.com/mvz/ripper_ruby_parser"

  s.rdoc_options = ["--main", "README.rdoc"]

  s.files = Dir['{lib,test}/**/*', "*.rdoc", "Rakefile"] & `git ls-files -z`.split("\0")
  s.extra_rdoc_files = ["README.rdoc"]
  s.test_files = `git ls-files -z -- test`.split("\0")

  s.add_dependency('sexp_processor', ["~> 3.0.10"])

  s.add_development_dependency('minitest', ["~> 2.11.2"])
  s.add_development_dependency('rake', ["~> 0.9.2"])
  s.add_development_dependency('ruby_parser', ["~> 2.3.1"])
  s.add_development_dependency('simplecov')

  s.required_ruby_version = '~> 1.9.3'

  s.require_paths = ["lib"]
end
