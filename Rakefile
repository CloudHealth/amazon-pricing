require 'bundler'
require 'rake/testtask'

$: << File.expand_path(File.dirname(__FILE__), 'lib')

require File.join('amazon-pricing','version')

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/*_test.rb'
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

desc "Prints current EC2 pricing in CSV format"
task :print_ec2_price_list do
  require 'amazon-pricing'
  pricing = AwsPricing::Ec2PriceList.new
  print_ec2_table(pricing)
end

desc "Prints current EC2 DI pricing in CSV format"
task :print_ec2_di_price_list do
  require 'amazon-pricing'
  pricing = AwsPricing::Ec2DiPriceList.new
  print_ec2_table(pricing)
end

desc "Prints current EC2 Dedicated Host pricing in CSV format"
task :print_ec2_dh_price_list do
  require 'amazon-pricing'
  pricing = AwsPricing::Ec2DedicatedHostPriceList.new
  print_ec2_dh_table(pricing)
end

desc "Prints current RDS pricing in CSV format"
task :print_rds_price_list do
  require 'amazon-pricing'
  pricing = AwsPricing::RdsPriceList.new
  print_rds_table(pricing) 
end

desc "Prints current ElastiCache pricing to CSV format"
task :print_elasticache_price_list do
  require 'amazon-pricing'
  pricing = AwsPricing::ElastiCachePriceList.new
  print_elasticache_table(pricing)
end

desc "Prints current GovCloud EC2 pricing in CSV format"
task :print_govcloud_ec2_price_list do
  require 'amazon-pricing'
  pricing = AwsPricing::Ec2PriceList.new
  print_ec2_table(pricing, "us-gov-west-1")
end

desc "Prints current GovCloud RDS pricing in CSV format"
task :print_govcloud_rds_price_list do
  require 'amazon-pricing'
  pricing = AwsPricing::Ec2PriceList.new
  print_rds_table(pricing, "us-gov-west-1")
end

task :default => [:test]

#########################################

def print_ec2_table(pricing, target_region = nil)
  line = "Region,Instance Type,API Name,Memory (MB),Disk (GB),Compute Units,Virtual Cores,Disk Type,OD Linux PPH,OD Windows PPH,OD RHEL PPH,OD SLES PPH,OD MsWinSQL PPH,OD MsWinSQLWeb PPH,"
  [:year1, :year3].each do |term|
    [:light, :medium, :heavy, :allupfront, :partialupfront, :noupfront].each do |res_type|
      [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb].each do |os|
        line += "#{term} #{res_type} #{os} Prepay,#{term} #{res_type} #{os} PPH,"
      end
    end
  end
  puts line.chop
  pricing.regions.each do |region|
    next if region.name != target_region if target_region
    region.ec2_instance_types.each do |t|
      line = "#{region.name},#{t.name},#{t.api_name},#{t.memory_in_mb},#{t.disk_in_gb},#{t.compute_units},#{t.virtual_cores},#{t.disk_type},"
      [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb].each do |os|
        line += "#{t.price_per_hour(os, :ondemand)},"
      end
      [:year1, :year3].each do |term|
        [:light, :medium, :heavy, :allupfront, :partialupfront, :noupfront].each do |res_type|
          [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb].each do |os|
            line += "#{t.prepay(os, res_type, term)},#{t.price_per_hour(os, res_type, term)},"
          end
        end
      end
      puts line.chop
    end
  end
end

def print_ec2_dh_table(pricing, target_region = nil)
  line = "Region,Instance Type,API Name,Memory (MB),Disk (GB),Compute Units,Virtual Cores,Disk Type,OD Linux PPH,OD Windows PPH,OD RHEL PPH,OD SLES PPH,OD MsWinSQL PPH,OD MsWinSQLWeb PPH,"
  [:year1, :year3].each do |term|
    [:light, :medium, :heavy, :allupfront, :partialupfront, :noupfront].each do |res_type|
      [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb].each do |os|
        line += "#{term} #{res_type} #{os} Prepay,#{term} #{res_type} #{os} PPH,"
      end
    end
  end
  puts line.chop
  pricing.regions.each do |region|
    next if region.name != target_region if target_region
    region.ec2_dh_types.each do |t|
      line = "#{region.name},#{t.name},#{t.api_name},#{t.memory_in_mb},#{t.disk_in_gb},#{t.compute_units},#{t.virtual_cores},#{t.disk_type},"
      [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb].each do |os|
        line += "#{t.price_per_hour(os, :ondemand)},"
      end
      [:year1, :year3].each do |term|
        [:light, :medium, :heavy, :allupfront, :partialupfront, :noupfront].each do |res_type|
          [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb].each do |os|
            line += "#{t.prepay(os, res_type, term)},#{t.price_per_hour(os, res_type, term)},"
          end
        end
      end
      puts line.chop
    end
  end
end

def print_elasticache_table(pricing, target_region = nil)
  line = "Region,Node Type,API Name,Memmory (MB),Virtual Cores,Disk Type,OD PPH,"
  [:year1, :year3].each do |term|
    [:partialupfront].each do |res_type|
      [:memcached].each do |cache|
        line += "#{term} #{res_type} #{cache} Prepay,#{term} #{res_type} #{cache} PPH,"
      end
    end
  end
  puts line.chop
  pricing.regions.each do |region|
    next if region.name != target_orgion if target_region
    region.elasticache_node_types.each do |t|
      line = "#{region.name},#{t.name},#{t.api_name},#{t.memory_in_mb},#{t.virtual_cores},"
      [:memcached].each do |cache|
        line += "#{t.price_per_hour(cache, :ondemand)},"
      end
      [:year1, :year3].each do |term|
        [:partialupfront].each do |res_type|
          [:memcached].each do |cache|
            line += "#{t.prepay(cache, res_type, term)},#{t.price_per_hour(cache, res_type, term)},"
          end
        end
      end
      puts line.chop
    end
  end
end

def print_rds_table(pricing, target_region = nil)
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
   [:light, :medium, :heavy, :allupfront, :partialupfront, :noupfront].each do |res_type|
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
    next if region.name != target_region if target_region
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
       [:light, :medium, :heavy, :allupfront, :partialupfront, :noupfront].each do |res_type|
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
