# frozen_string_literal: true

source 'https://rubygems.org'

# The gem's dependencies are specified in the gemspec
gemspec

# For testing, do not allow sexp_processor 4.12.1: its test cases match an
# unreleased version of ruby_parser.
gem 'sexp_processor', ['~> 4.10', '< 4.12.1']

group :local_development do
  gem 'pry'
end
