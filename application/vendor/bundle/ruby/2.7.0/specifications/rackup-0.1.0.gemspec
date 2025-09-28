# -*- encoding: utf-8 -*-
# stub: rackup 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rackup".freeze
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rack Contributors".freeze]
  s.date = "2022-08-03"
  s.homepage = "https://github.com/rack/rackup".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A general server command for Rack applications.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rack>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<webrick>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_development_dependency(%q<minitest-sprint>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest-global_expectations>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rack>.freeze, [">= 0"])
    s.add_dependency(%q<webrick>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_dependency(%q<minitest-sprint>.freeze, [">= 0"])
    s.add_dependency(%q<minitest-global_expectations>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
