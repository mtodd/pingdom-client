require "rubygems"
require "bundler"
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
  t.pattern = 'spec/**/*_spec.rb'
end

task :console do
  exec %(ruby -rirb -rubygems -r bundler/setup -r lib/pingdom-ruby -e '$credentials = YAML.load_file("credentials.yml").with_indifferent_access; $client = Pingdom::Client.new($credentials); IRB.start')
end

task :default => :spec
