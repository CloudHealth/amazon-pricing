require 'bundler'
require 'rake/testtask'

$: << File.expand_path(File.dirname(__FILE__), 'lib')

#require 'amazon-pricing/version'

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
task :print_price_list do
  require 'lib/amazon-pricing'
  pricing = AwsPricing::PriceList.new
  line = "Region,Instance Type,API Name,Memory (MB),Disk (MB),Compute Units, Virtual Cores,OD Linux PPH,OD Windows PPH,OD RHEL PPH,OD SLES PPH,OD MsWinSQL PPH,OD MsWinSQLWeb PPH,"
  [:year1, :year3].each do |term|
    [:light, :medium, :heavy].each do |res_type|
      [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb].each do |os|
        line += "#{term} #{res_type} #{os} Prepay,#{term} #{res_type} #{os} PPH,"
      end
    end
  end
  puts line.chop
  pricing.regions.each do |region|
    region.instance_types.each do |t|
      line = "#{region.name},#{t.name},#{t.api_name},#{t.memory_in_mb},#{t.disk_in_mb},#{t.compute_units},#{t.virtual_cores},"
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
  require 'lib/amazon-pricing'
  pricing = AwsPricing::RdsPriceList.new

  @ON_DEMAND_RDS_DB_INSTANCES = {
                                    :mysql=> ["standard","multiAZ"],
                                    :oracle=> ["li-standard","li-multiAZ","byol-standard","byol-multiAZ"],
                                    :sqlserver=>["li-ex","li-web","li-se","byol"]
                                 }

  @RESERVED_RDS_DB_INSTANCES = {
                                    :mysql=> ["standard","multiAZ"],
                                    :oracle=> ["li-standard","li-multiAZ","byol-standard","byol-multiAZ"],
                                    :sqlserver=> ['li-ex','li-web','li-se','byol']
                                }

  line = "Region,Instance Type,API Name,Memory (MB),Disk (MB),Compute Units, Virtual Cores,"

  [:mysql,:oracle, :sqlserver].each do |db|
    @ON_DEMAND_RDS_DB_INSTANCES[db].each do |deploy_type|
      line += "OD #{db} #{deploy_type} PPH,"
    end
  end

  [:year1, :year3].each do |term|
    [:light, :medium, :heavy].each do |res_type|
      [:mysql,:oracle, :sqlserver].each do |db|
        @RESERVED_RDS_DB_INSTANCES[db].each do |deploy_type|
          line += "#{term} #{res_type} #{db} #{deploy_type} Prepay,#{term} #{res_type} #{db} #{deploy_type} PPH,"
        end
      end
    end
  end

  puts line.chop

  pricing.regions.each do |region|
    region.instance_types.each do |t|
      line = "#{region.name},#{t.name},#{t.api_name},#{t.memory_in_mb},#{t.disk_in_mb},#{t.compute_units},#{t.virtual_cores},"
      [:mysql,:oracle, :sqlserver].each do |db|
        @ON_DEMAND_RDS_DB_INSTANCES[db].each do |deploy_type|
          line += "#{t.price_per_hour(db, :ondemand, nil,deploy_type.gsub("-","_"))},"
        end
      end

      [:year1, :year3].each do |term|
        [:light, :medium, :heavy].each do |res_type|
          [:mysql,:oracle, :sqlserver].each do |db|
            @RESERVED_RDS_DB_INSTANCES[db].each do |deploy_type|
              line += "#{t.prepay(db, res_type, term, deploy_type.gsub("-","_"))},#{t.price_per_hour(db, res_type, term, deploy_type.gsub("-","_"))},"
            end
          end
        end
      end
       puts line.chop
    end
  end
end
