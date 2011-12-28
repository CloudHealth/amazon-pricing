# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "aws-pricing/version"

Gem::Specification.new do |s|
  s.name        = "amazon-pricing"
  s.version     = AwsPricing::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Joe Kinsella"]
  s.email       = ["joe.kinsella@gmail.com"]
  s.homepage    = "http://github.com/sonian/amazon-pricing"
  s.summary     = "Amazon Web Services Pricing Ruby gem"
  s.description = "A Ruby library for retrieving pricing for Amazon Web Services"

  s.rubyforge_project = "amazon-pricing"

  s.rdoc_options = ["--title", "amazon-pricing documentation", "--line-numbers", "--main", "README.rdoc"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]

   s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end