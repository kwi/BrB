require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

spec_files = Rake::FileList["spec/**/*_spec.rb"]

desc "Run specs for current Rails version"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = spec_files
  t.spec_opts = ["-c"]
end

task :default => :spec

desc "Run simple core"
task :simple_core_example do
  require 'examples/simple_core'
end

desc "Run simple client (call simple_core_before)"
task :simple_client_example do
  require 'examples/simple_client'
end