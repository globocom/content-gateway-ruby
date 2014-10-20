lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'content_gateway/version'

Gem::Specification.new do |gem|
  gem.name          = "content_gateway"
  gem.version       = ContentGateway::VERSION
  gem.authors       = ["Webmedia"]
  gem.email         = ["webmedia@corp.globo.com"]
  gem.description   = %q{An easy way to get external content with two cache levels. The first is a performance cache and second is the stale}
  gem.summary       = %q{Content Gateway}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "activesupport"
  gem.add_dependency "rest-client"
  gem.add_dependency "json"

  gem.add_development_dependency "rspec",                       ">= 2.3.0"
  gem.add_development_dependency "simplecov",                   ">= 0.7.1"
  gem.add_development_dependency "byebug"
end
