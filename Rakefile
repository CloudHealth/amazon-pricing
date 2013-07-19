require 'bundler'
require 'rake/testtask'

$: << File.expand_path(File.dirname(__FILE__), 'lib')

require 'amazon-pricing/version'

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end


desc "Build the gem"
task :gem do
  sh 'gem build *.gemspec'
end

desc "Publish the gem"
task :publish do
  sh "gem push amazon-pricing-#{AwsPricing::VERSION}.gem"
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
  puts "Region,Instance Type,Prepay 1 Year,Prepay 3 Year,Linux PPH,Windows PPH,RHEL PPH,SLES PPH,MSWinSQL PPH,MsWinSQLWeb PPH,3 Year Linux PPH,3 Year Windows PPH,3 Year RHEL PPH,3 Year SLES PPH,3 Year MSWinSQL PPH,3 Year MsWinSQLWeb PPH"
  pricing.regions.each do |region|
    region.ec2_on_demand_instance_types.each do |t|
      puts "#{region.name},on-demand,#{t.api_name},0,0,#{t.linux_price_per_hour},#{t.windows_price_per_hour},#{t.rhel_price_per_hour},#{t.sles_price_per_hour},#{t.mswinSQL_price_per_hour},#{t.mswinSQLWeb_price_per_hour},N/A,N/A,N/A,N/A,N/A,N/A"
    end
    region.ec2_reserved_instance_types.each do |t|
      puts "#{region.name},#{t.usage_type},#{t.api_name},#{t.prepay_1_year},#{t.prepay_3_year},#{t.linux_price_per_hour},#{t.windows_price_per_hour},#{t.rhel_price_per_hour},#{t.sles_price_per_hour},#{t.mswinSQL_price_per_hour},#{t.mswinSQLWeb_price_per_hour},#{t.linux_price_per_hour_3_year},#{t.windows_price_per_hour_3_year},#{t.rhel_price_per_hour_3_year},#{t.sles_price_per_hour_3_year},#{t.mswinSQL_price_per_hour_3_year},#{t.mswinSQLWeb_price_per_hour_3_year}"
    end
  end
end

task :default => [:test]
