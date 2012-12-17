$:.push File.extend_path "../lib", __FILE__             # why?

Gem::Specification.new do |gem|
  gem.name     = 'djula'
  gem.version  = '0.0.0'
  gem.summary  = 'HTML Templating'
  gem.homepage = 'https://github.com/ginzamarkets/djula'
  gem.author   = 'Nick Allen'
  gem.email    = 'nick@ginzametrics.com'

  gem.files       = `git ls-files -z`.split "\n"
  gem.executables = gem.files.grep(%r{^bin/}).map { |path| File.basename path }
  gem.test_files  = gem.files.grep %r{^spec/.*\.rb$}
  gem.require_paths = ["lib"]

#  gem.add_dependency 'redis'

#  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'minitest', '~> 3.0'
#  gem.add_development_dependency 'mock_redis', '>= 0.5.2'
  gem.add_development_dependency 'rake'
#  gem.add_development_dependency 'rb-inotify'
#  gem.add_development_dependency 'rerun'
end