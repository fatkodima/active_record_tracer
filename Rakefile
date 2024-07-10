# frozen_string_literal: true

require "bundler/gem_tasks"

require "rubocop/rake_task"
RuboCop::RakeTask.new

require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: [:rubocop, :test]
