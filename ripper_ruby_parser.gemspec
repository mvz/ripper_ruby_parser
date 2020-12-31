# frozen_string_literal: true

require_relative "lib/ripper_ruby_parser/version"

Gem::Specification.new do |spec|
  spec.name = "ripper_ruby_parser"
  spec.version = RipperRubyParser::VERSION
  spec.authors = ["Matijs van Zuijlen"]
  spec.email = ["matijs@matijs.net"]

  spec.summary = "Parse with Ripper, produce sexps that are compatible with RubyParser."
  spec.description = <<~DESC
    RipperRubyParser is a parser for Ruby based on Ripper that aims to be a
    drop-in replacement for RubyParser.
  DESC
  spec.homepage = "http://www.github.com/mvz/ripper_ruby_parser"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mvz/ripper_ruby_parser"
  spec.metadata["changelog_uri"] = "https://github.com/mvz/ripper_ruby_parser/blob/master/CHANGELOG.md"

  spec.files = File.read("Manifest.txt").split
  spec.rdoc_options = ["--main", "README.md"]
  spec.extra_rdoc_files = ["README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "sexp_processor", "~> 4.10"

  spec.add_development_dependency "minitest", "~> 5.6"
  spec.add_development_dependency "pry", "~> 0.13.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-manifest", "~> 0.1.0"
  spec.add_development_dependency "rubocop", "~> 1.7.0"
  spec.add_development_dependency "rubocop-minitest", "~> 0.10.0"
  spec.add_development_dependency "rubocop-performance", "~> 1.9.0"
  spec.add_development_dependency "ruby_parser", "~> 3.15.0"
  # For testing, require sexp_processor 4.13, 4.14 or 4.15 so its test cases
  # match version 3.14.0 of ruby_parser.
  spec.add_development_dependency "sexp_processor", [">= 4.13.0", "< 4.16"]
  spec.add_development_dependency "simplecov", "~> 0.20.0"
end
