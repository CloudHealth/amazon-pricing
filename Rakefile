require 'bundler'
require 'rake/testtask'

$: << File.expand_path(File.dirname(__FILE__), 'lib')

require File.join('amazon-pricing','version')

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
  sh "sudo gem install amazon-pricing-#{AwsPricing::VERSION}.gem --no-rdoc --no-ri"
end

task :test do
  ruby "test/test-ec2-instance-types.rb"
end

desc "Prints current EC2 pricing in CSV format"
task :print_ec2_price_list do
  require 'amazon-pricing'
  pricing = AwsPricing::Ec2PriceList.new
  line = "Region,Instance Type,API Name,Memory (MB),Disk (GB),Compute Units,Virtual Cores,Disk Type,OD Linux PPH,OD Windows PPH,OD RHEL PPH,OD SLES PPH,OD MsWinSQL PPH,OD MsWinSQLWeb PPH,"
  [:year1, :year3].each do |term|
    [:light, :medium, :heavy].each do |res_type|
      [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb].each do |os|
        line += "#{term} #{res_type} #{os} Prepay,#{term} #{res_type} #{os} PPH,"
      end
    end
  end
  puts line.chop
  pricing.regions.each do |region|
    region.ec2_instance_types.each do |t|
      line = "#{region.name},#{t.name},#{t.api_name},#{t.memory_in_mb},#{t.disk_in_gb},#{t.compute_units},#{t.virtual_cores},#{t.disk_type},"
      [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb].each do |os|
        line += "#{t.price_per_hour(os, :ondemand)},"
      end
      [:year1, :year3].each do |term|
        [:light, :medium, :heavy].each do |res_type|
          [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb].each do |os|
            line += "#{t.prepay(os, res_type, term)},#{t.price_per_hour(os, res_type, term)},"
          end
        end
      end
      puts line.chop
    end
  end
end


desc "Prints current RDS pricing in CSV format"
task :print_rds_price_list do
  require 'amazon-pricing'
  pricing = AwsPricing::RdsPriceList.new
  
  line = "Region,Instance Type,API Name,Memory (MB),Disk (GB),Compute Units,Virtual Cores,Disk Type,"
  
  AwsPricing::DatabaseType.get_database_name.each do |db|
    unless AwsPricing::DatabaseType.get_available_types(db).nil?
      AwsPricing::DatabaseType.get_available_types(db).each do |deploy_type|
        line += "OD "+ AwsPricing::DatabaseType.display_name("#{db}_#{deploy_type}") +" PPH,"
      end
    else
      line += "OD "+ AwsPricing::DatabaseType.display_name(db.to_s) +" PPH,"
    end      
  end

  [:year1, :year3].each do |term|
   [:light, :medium, :heavy].each do |res_type|
       AwsPricing::DatabaseType.get_database_name.each do |db|
          unless AwsPricing::DatabaseType.get_available_types(db).nil?
            AwsPricing::DatabaseType.get_available_types(db).each do |deploy_type|
              line += "#{term} #{res_type} "+ AwsPricing::DatabaseType.display_name("#{db}_#{deploy_type}") +" Prepay,#{term} #{res_type} "+ AwsPricing::DatabaseType.display_name("#{db}_#{deploy_type}") +" PPH,"
            end
          else
            line += "#{term} #{res_type} "+ AwsPricing::DatabaseType.display_name(db.to_s) +" Prepay,#{term} #{res_type} "+ AwsPricing::DatabaseType.display_name(db.to_s) +" PPH,"
          end
       end
   end
  end

 
 puts line.chop

 pricing.regions.each do |region|
   region.rds_instance_types.each do |t|
     line = "#{region.name},#{t.name},#{t.api_name},#{t.memory_in_mb},#{t.disk_in_gb},#{t.compute_units},#{t.virtual_cores},#{t.disk_type},"
     AwsPricing::DatabaseType.get_database_name.each do |db|
       unless AwsPricing::DatabaseType.get_available_types(db).nil?
          AwsPricing::DatabaseType.get_available_types(db).each do |deploy_type|
            if deploy_type == :byol_multiaz
              line += "#{t.price_per_hour(db, :ondemand, nil, true, true)},"
            else
              line += "#{t.price_per_hour(db, :ondemand, nil, deploy_type == :multiaz, deploy_type == :byol)},"
            end  
          end
       else
          line += "#{t.price_per_hour(db, :ondemand, nil)},"
       end
     end
     [:year1, :year3].each do |term|
       [:light, :medium, :heavy].each do |res_type|
         AwsPricing::DatabaseType.get_database_name.each do |db|
            unless AwsPricing::DatabaseType.get_available_types(db).nil?
              AwsPricing::DatabaseType.get_available_types(db).each do |deploy_type|
                if deploy_type == :byol_multiaz
                  line += "#{t.prepay(db, res_type, term, true, true)},#{t.price_per_hour(db, res_type, term, true, true)},"
                else  
                  line += "#{t.prepay(db, res_type, term, deploy_type == :multiaz, deploy_type == :byol)},#{t.price_per_hour(db, res_type, term, deploy_type == :multiaz, deploy_type == :byol)},"
                end  
              end
            else
              line += "#{t.prepay(db, res_type, term)},#{t.price_per_hour(db, res_type, term)},"
            end
         end
       end
     end
     puts line.chop
   end
 end
end

task :default => [:test]
