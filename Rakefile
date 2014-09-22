require "bundler/gem_tasks"

# Rake tasks
Dir.glob('lib/tasks/**/*.rake').each {|r| import r}

require "rspec/core/rake_task"
desc "Run all examples"
RSpec::Core::RakeTask.new(:spec)

task :default => :spec
