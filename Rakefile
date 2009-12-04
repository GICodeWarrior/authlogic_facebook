require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "authlogic_facebook"
    gem.summary = %Q{Authlogic plugin to support Facebook without Facebooker}
    gem.description = %Q{Authlogic plugin to support Facebook without Facebooker.  A small unobtrusive gem (mini_fb) is used instead.}
    gem.email = "GICodeWarrior@gmail.com"
    gem.homepage = "http://github.com/GICodeWarrior/authlogic_facebook"
    gem.authors = ["Rusty Burchfield"]
    gem.add_dependency "mini_fb", ">= 0.1.0"
    gem.add_dependency "authlogic", ">= 2.1.3"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "authlogic_facebook #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
