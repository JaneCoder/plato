ROOT_DIR = File.expand_path(File.dirname(__FILE__))

require 'rubygems' rescue nil
require 'rake'
require 'spec/rake/spectask'

task :default => :spec

desc "Run all specs in spec directory."
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--options', "\"#{ROOT_DIR}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

# gemification with jeweler
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "plato"
    gemspec.summary = "An ideal static site generator"
    gemspec.description = "use templates and content to generate static sites."
    gemspec.email = "matt@freels.name"
    gemspec.homepage = "http://github.com/freels/plato"
    gemspec.authors = ["Matt Freels"]
    gemspec.add_dependency 'tilt', '>= 1.0.1'

    # development
    gemspec.add_development_dependency 'rspec'
    gemspec.add_development_dependency 'rr'
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
