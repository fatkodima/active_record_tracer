# frozen_string_literal: true

require_relative "lib/active_record_tracer/version"

Gem::Specification.new do |spec|
  spec.name = "active_record_tracer"
  spec.version = ActiveRecordTracer::VERSION
  spec.authors = ["fatkodima"]
  spec.email = ["fatkodima123@gmail.com"]

  spec.summary = "A tracer for Active Record queries"
  spec.homepage = "https://github.com/fatkodima/active_record_tracer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.files = Dir["**/*.{md,txt}", "{lib}/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.0"
end
