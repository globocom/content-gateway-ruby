lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'content_gateway/version'

Gem::Specification.new do |gem|
  gem.name          = "content_gateway"
  gem.version       = ContentGateway::VERSION
  gem.authors       = ["Túlio Ornelas", "Roberto Soares", "Emerson Macedo", "Guilherme Garnier", "Daniel Martins", "Rafael Biriba", "Célio Latorraca"]
  gem.email         = ["ornelas.tulio@gmail.com", "roberto.tech@gmail.com", "emerleite@gmail.com", "guilherme.garnier@gmail.com", "daniel.tritone@gmail.com", "biribarj@gmail.com", "celio.la@gmail.com"]
  gem.description   = %q{An easy way to get external content with two cache levels. The first is a performance cache and second is the stale}
  gem.summary       = %q{Content Gateway}
  gem.homepage      = "https://github.com/globocom/content-gateway-ruby"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "activesupport",                           ">= 3"
  gem.add_dependency "rest-client",                             "~> 2.1"
  gem.add_dependency "json",                                    "~> 1.0"

  gem.add_development_dependency "rspec",                       ">= 2.3.0"
  gem.add_development_dependency "simplecov",                   ">= 0.7.1"
  gem.add_development_dependency "byebug"
  gem.add_development_dependency "rake"
end
