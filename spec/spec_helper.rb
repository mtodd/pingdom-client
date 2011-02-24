$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
require 'rubygems'
require 'bundler/setup'
require 'pingdom-client'

require 'rspec'

CREDENTIALS = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'credentials.yml')).inject({}){ |h,(k,v)| h[k.to_sym] = v; h }
