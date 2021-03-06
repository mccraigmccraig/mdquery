# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "mdquery"
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["mccraigmccraig"]
  s.date = "2014-06-25"
  s.description = "provides a DSL for simply specifying and executing segmented multi-dimensional queries on your active-record-3 models"
  s.email = "mccraigmccraig@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    ".travis.yml",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/mdquery.rb",
    "lib/mdquery/dataset.rb",
    "lib/mdquery/dsl.rb",
    "lib/mdquery/model.rb",
    "lib/mdquery/util.rb",
    "mdquery.gemspec",
    "spec/mdquery/dataset_spec.rb",
    "spec/mdquery/dsl_spec.rb",
    "spec/mdquery/model_spec.rb",
    "spec/mdquery/util_spec.rb",
    "spec/mdquery_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/mccraigmccraig/mdquery"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "simple multi-dimensional queries on top of active-record-3"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, [">= 3.1.0"])
      s.add_development_dependency(%q<rake>, ["~> 10.2.2"])
      s.add_development_dependency(%q<rspec>, ["~> 2.14.1"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.1.1"])
      s.add_development_dependency(%q<bundler>, ["~> 1.6.3"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_development_dependency(%q<rr>, [">= 1.1.2"])
    else
      s.add_dependency(%q<activerecord>, [">= 3.1.0"])
      s.add_dependency(%q<rake>, ["~> 10.2.2"])
      s.add_dependency(%q<rspec>, ["~> 2.14.1"])
      s.add_dependency(%q<rdoc>, ["~> 4.1.1"])
      s.add_dependency(%q<bundler>, ["~> 1.6.3"])
      s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_dependency(%q<rr>, [">= 1.1.2"])
    end
  else
    s.add_dependency(%q<activerecord>, [">= 3.1.0"])
    s.add_dependency(%q<rake>, ["~> 10.2.2"])
    s.add_dependency(%q<rspec>, ["~> 2.14.1"])
    s.add_dependency(%q<rdoc>, ["~> 4.1.1"])
    s.add_dependency(%q<bundler>, ["~> 1.6.3"])
    s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
    s.add_dependency(%q<rr>, [">= 1.1.2"])
  end
end

