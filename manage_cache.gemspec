$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "manage_cache/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "manage_cache"
  s.version     = ManageCache::VERSION
  s.authors     = ["cgregor"]
  s.email       = ["chrgregor@gmail.com"]
  s.homepage    = "https://github.com/grgr/manage_cache"
  s.summary     = "rails: manage cache deletion and cache_keys in ActiveRecord"
  s.description = "rails: manage cache deletion and cache_keys in ActiveRecord"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"#, "~> 4.2.5"

  s.add_development_dependency "sqlite3"
end
