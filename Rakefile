require 'bundler'
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end


desc "Build the gem"
task :gem do
  sh 'gem build *.gemspec'
end

desc "Installs the gem"
task :install => :gem do
  sh "#{SUDO} gem install amazon-pricing.gem --no-rdoc --no-ri"
end

task :test do
  ruby "test/test-ec2-instance-types.rb"
end

desc "Prints current EC2 pricing to console"
task :print_price_list do
  require 'lib/amazon-pricing'
  pricing = AwsPricing::PriceList.new
  pricing.regions.each do |region|
    puts "Region: #{region.name}"
    puts "   On-demand instances"
    region.ec2_on_demand_instance_types.each do |instance_type|
      puts "      #{instance_type.to_s}"
    end
    puts "   Reserved instances"
    region.ec2_reserved_instance_types.each do |instance_type|
      puts "      #{instance_type.to_s}"
    end
  end
end

task :default => [:test]
