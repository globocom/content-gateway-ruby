namespace :content_gateway do
  desc "releases version on artifactory.globoi.com"
  task :release do
    puts "== Building content_gateway-#{ContentGateway::VERSION}.gem"
    Rake::Task["build"].execute

    puts "== Pushing to 'http://artifactory.globoi.com/' with key 'rubygems_artifact_api_key'"
    system %Q{gem push pkg/content_gateway-#{ContentGateway::VERSION}.gem --host "http://artifactory.globoi.com/artifactory/api/gems/gem-local" -k rubygems_artifact_api_key}
  end
end
