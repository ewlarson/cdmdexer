# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cdmdexer/version'

Gem::Specification.new do |spec|
  spec.name          = 'cdmdexer'
  spec.version       = CDMDEXER::VERSION
  spec.authors       = ['chadfennell']
  spec.email         = ['fenne035@umn.edu']

  spec.summary       = 'Load CONTENTdm data into a Solr Index. CDMDEXER expects to run inside a Rails application.'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'contentdm_api', '~> 0.6.0'
  spec.add_dependency 'hash_at_path', '~> 0.1.6'
  spec.add_dependency 'rsolr', '~> 2.0'
  spec.add_dependency 'sidekiq', '>= 3.5'
  spec.add_dependency 'titleize', '~> 1.4'
  # CDMDEXER expects to run in a rails app, but just to avoid adding
  # another external dependency for XML procssing, we rely on activesupport's
  # Has.to_jsonl feature for testing and to allow this gem to function
  # independently from a rails app
  spec.add_dependency 'rails', '~> 6.0'
  spec.add_dependency 'rexml', '~> 3.2'

  spec.add_development_dependency 'dotenv-rails', '~> 2.7.6'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'yard', '~> 0.9.0'
end
