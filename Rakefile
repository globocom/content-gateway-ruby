require "bundler/gem_tasks"

# Rake tasks
Dir.glob('lib/tasks/**/*.rake').each {|r| import r}

require "rspec/core/rake_task"
desc "Run all examples"
RSpec::Core::RakeTask.new(:spec)

task :default => :spec


# Monkey patch para publicar gems internamente
module Bundler
    class GemHelper
        def rubygem_push(path)
            gem_server_url = 'https://artifactory.globoi.com/artifactory/api/gems/gem-local'

            if Pathname.new("~/.gem/credentials").expand_path.exist?
                sh("gem push '#{path}' --host #{gem_server_url}")
                Bundler.ui.confirm "Pushed #{name} #{version} to #{gem_server_url}"
            else
                raise "Your credentials aren't set. Run `gem push` to set them."
            end
        end
    end
end
