# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in active_record_tracer.gemspec
gemspec

gem "rake", "~> 13.0"
gem "minitest"
gem "sqlite3", "< 2"
gem "rubocop"
gem "rubocop-minitest"

if defined?(@ar_gem_requirement)
  gem "activerecord", @ar_gem_requirement
else
  gem "activerecord" # latest
end
