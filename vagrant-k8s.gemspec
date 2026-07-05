# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = 'vagrant-k8s'
  spec.version     = File.read(File.join(__dir__, 'lib/vagrant-k8s/VERSION')).strip
  spec.summary     = 'Vagrant integration for Kubernetes with Helm and Kustomize provisioners'
  spec.description = 'Configures a Kubernetes cluster from a Vagrantfile and provides Helm and Kustomize provisioners.'
  spec.authors     = ['Julien Poirou']
  spec.email       = ['julienpoirou@protonmail.com']
  spec.homepage    = 'https://github.com/julienpoirou/vagrant-k8s'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 3.1'
  spec.files = Dir['lib/**/*', 'README.md', 'README.fr.md', 'LICENSE.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.75'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.6'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'bug_tracker_uri' => 'https://github.com/julienpoirou/vagrant-k8s/issues',
    'changelog_uri' => 'https://github.com/julienpoirou/vagrant-k8s/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://www.rubydoc.info/gems/vagrant-k8s/',
    'source_code_uri' => 'https://github.com/julienpoirou/vagrant-k8s',
    'homepage_uri' => 'https://github.com/julienpoirou/vagrant-k8s'
  }
end
