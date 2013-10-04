Gem::Specification.new do |s|
  s.name = %q{pingdom-client}
  s.version = "0.0.7"
  
  s.authors = ["Matt Todd"]
  s.date = %q{2011-03-02}
  s.description = %q{Pingdom Ruby Client}
  s.email = %q{chiology@gmail.com}
  s.files = [
    "pingdom-client.gemspec",
    "Gemfile",
    "Gemfile.lock",
    "lib/pingdom/base.rb",
    "lib/pingdom/check.rb",
    "lib/pingdom/client.rb",
    "lib/pingdom/contact.rb",
    "lib/pingdom/probe.rb",
    "lib/pingdom/result.rb",
    "lib/pingdom/summary/average.rb",
    "lib/pingdom/summary/outage.rb",
    "lib/pingdom/summary/performance.rb",
    "lib/pingdom/summary.rb",
    "lib/pingdom-client.rb",
    "lib/pingdom.rb",
    "lib/tinder/faraday_response.rb",
    "Rakefile",
    "Readme.md",
    "spec/pingdom-client_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Pingdom Ruby Client}
  s.test_files = [
    "spec/spec_helper.rb",
    "spec/pingdom-client_spec.rb"
  ]
end
