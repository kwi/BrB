Gem::Specification.new do |s|
  s.name = "brb"
  s.version = "0.3.0"
  s.author = "Guillaume Luccisano"
  s.email = "guillaume.luccisano@gmail.com"
  s.homepage = "http://github.com/kwi/BrB"
  s.summary = "BrB is a simple, fully transparent and extremely fast interface for doing simple distributed ruby"
  s.description = "BrB is a simple, fully transparent and extremely fast interface for doing simple distributed ruby and message passing"
  s.requirements << 'eventmachine'

  s.add_dependency('eventmachine', '> 0.12')


  s.files = Dir["{examples,lib,spec}/**/*", "[A-Z]*", "init.rb"]
  s.require_path = "lib"

  s.rubyforge_project = s.name
  s.required_rubygems_version = ">= 1.3.4"
end