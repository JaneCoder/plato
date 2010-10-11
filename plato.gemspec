# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{plato}
  s.version = "0.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Freels"]
  s.date = %q{2010-10-10}
  s.description = %q{use templates and content to generate static sites.}
  s.email = %q{matt@freels.name}
  s.executables = ["plato", "plato-prepare-repo"]
  s.files = [
    ".gitignore",
     "Rakefile",
     "VERSION",
     "bin/plato",
     "bin/plato-prepare-repo",
     "dist/hooks/post-receive",
     "lib/plato.rb",
     "lib/plato/config.rb",
     "lib/plato/document.rb",
     "lib/plato/headers_codec.rb",
     "lib/plato/manifest.rb",
     "lib/plato/path_template.rb",
     "lib/plato/rendering.rb",
     "lib/plato/repo.rb",
     "lib/plato/site.rb",
     "plato.gemspec"
  ]
  s.homepage = %q{http://github.com/freels/plato}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{An ideal static site generator}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<tilt>, ["~> 1.0.1"])
      s.add_runtime_dependency(%q<ruby_archive>, ["~> 0.1.2"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<rr>, [">= 0"])
    else
      s.add_dependency(%q<tilt>, ["~> 1.0.1"])
      s.add_dependency(%q<ruby_archive>, ["~> 0.1.2"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<rr>, [">= 0"])
    end
  else
    s.add_dependency(%q<tilt>, ["~> 1.0.1"])
    s.add_dependency(%q<ruby_archive>, ["~> 0.1.2"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<rr>, [">= 0"])
  end
end

