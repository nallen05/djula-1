require 'rubygems'
#require 'bundler/gem_tasks'
require 'rake/testtask'


task :default => :spec

## todo: figure out how not to have to do this...
unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))
  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
end

unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__))+"/lib")
  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__))+"/lib")
end


namespace :djula do
  desc 'Start the interactive mock up server for TEMPLATE_FOLDER (on PORT)'
  task :example do
    template_folder = (ENV['TEMPLATE_FOLDER'] or Dir::pwd)
    port = (ENV['PORT'] or 3001)
    require 'djula' # how not to have to do this?
    s = Djula::Server.new template_folder, :port => port
    s.start
  end
end

Rake::TestTask.new :spec do |task|
  task.test_files = FileList['spec/**/*_spec.rb']
end