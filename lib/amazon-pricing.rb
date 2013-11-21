require 'json'
require 'net/http'

Dir[File.join(File.dirname(__FILE__), 'amazon-pricing/*.rb')].sort.each { |lib| require lib }

#--
# Amazon Web Services Pricing Ruby library
#
# Ruby Gem Name::  amazon-pricing
# Author::    Joe Kinsella (mailto:joe.kinsella@gmail.com)
# Copyright:: Copyright (c) 2011-2013 CloudHealth
# License::   Distributes under the same terms as Ruby
# Home::      http://github.com/CloudHealth/amazon-pricing
#++
module AwsPricing

  # PriceList provides the primary interface for retrieving AWS pricing.
  # Upon instantiating a PriceList object, all the corresponding pricing
  # information will be retrieved from Amazon via currently undocumented
  # json APIs.
    class PriceList
    attr_accessor :regions

    def get_region(name)
      @_regions[@@Region_Lookup[name] || name]
    end

    def regions
      @_regions.values
    end

    def get_instance_type(region_name, api_name)
      region = get_region(region_name)
      raise "Region #{region_name} not found" if region.nil?
      region.get_instance_type(api_name)
    end

    def fetch_url(url)
      uri = URI.parse(url)
      page = Net::HTTP.get_response(uri)
      JSON.parse(page.body)
    end

    protected

    attr_accessor :_regions

    def add_region(region)
      @_regions[region.name] = region
    end

    def find_or_create_region(name)
      region = get_region(name)
      if region.nil?
        region = Region.new(name)
        add_region(region)
      end
      region
    end

    EC2_BASE_URL = "http://aws.amazon.com/ec2/pricing/"
    RDS_BASE_URL = "http://aws.amazon.com/rds/pricing/"

    # Lookup allows us to map to AWS API region names
    @@Region_Lookup = {
      'us-east-1' => 'us-east',
      'us-west-1' => 'us-west',
      'us-west-2' => 'us-west-2',
      'eu-west-1' => 'eu-ireland',
      'ap-southeast-1' => 'apac-sin',
      'ap-southeast-2' => 'apac-syd',
      'ap-northeast-1' => 'apac-tokyo',
      'sa-east-1' => 'sa-east-1'
    }

  end


  class Ec2PriceList < PriceList
    
    def initialize
      @_regions = {}
      get_ec2_on_demand_instance_pricing
      get_ec2_reserved_instance_pricing
      fetch_ec2_ebs_pricing
    end

    protected

    @@OS_TYPES = [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb]
    @@RES_TYPES = [:light, :medium, :heavy]

    def get_ec2_on_demand_instance_pricing
      @@OS_TYPES.each do |os|
        fetch_ec2_instance_pricing(EC2_BASE_URL + "json/#{os}-od.json", :ondemand, os)
      end
    end

    def get_ec2_reserved_instance_pricing
      @@OS_TYPES.each do |os|
        @@RES_TYPES.each do |res_type|
          fetch_ec2_instance_pricing(EC2_BASE_URL + "json/#{os}-ri-#{res_type}.json", res_type, os)
        end
      end
    end

    # Retrieves the EC2 on-demand instance pricing.
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def fetch_ec2_instance_pricing(url, type_of_instance, operating_system)
      res = fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        # e.g. type = {"type"=>"hiCPUODI", "sizes"=>[{"size"=>"med", "valueColumns"=>[{"name"=>"mswinSQL", "prices"=>{"USD"=>"N/A"}}]}, {"size"=>"xl", "valueColumns"=>[{"name"=>"mswinSQL", "prices"=>{"USD"=>"2.427"}}]}]}
        reg['instanceTypes'].each do |type|
          # e.g. size = {"size"=>"xl", "valueColumns"=>[{"name"=>"mswinSQL", "prices"=>{"USD"=>"2.427"}}]}
          type['sizes'].each do |size|
            begin
              api_name, name = Ec2InstanceType.get_name(type["type"], size["size"], type_of_instance != :ondemand)
              
              region.add_or_update_ec2_instance_type(api_name, name, operating_system, type_of_instance, size)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    end

    def fetch_ec2_ebs_pricing
      res = fetch_url(EC2_BASE_URL + "pricing-ebs.json")
      res["config"]["regions"].each do |ebs_types|
        region = get_region(ebs_types["region"])
        region.ebs_price = EbsPrice.new(region, ebs_types)
      end
    end

  end

  class RdsPriceList < PriceList
    
    def initialize
      @_regions = {}
       get_rds_on_demand_instance_pricing
       get_rds_reserved_instance_pricing
    end

    protected

    @@DB_TYPE = [:mysql, :postgresql, :oracle, :sqlserver]
    @@RES_TYPES = [:light, :medium, :heavy]
    
    @@OD_DB_DEPLOY_TYPE = {
                           :mysql=> {:mysql=>["standard","multiAZ"]},
                           :postgresql=> {:postgresql=>["standard","multiAZ"]},
                           :oracle=> {:oracle_se1=>["li-standard","li-multiAZ","byol-standard","byol-multiAZ"], :oracle_se=>["byol-standard","byol-multiAZ"], :oracle_ee=>["byol-standard","byol-multiAZ"]},
                           :sqlserver=> {:sqlserver_ex=>["li-ex"], :sqlserver_web=>["li-web"], :sqlserver_se=>["li-se", "byol"], :sqlserver_ee=>["byol"]}
                        }


    @@RESERVED_DB_DEPLOY_TYPE = {
                           :oracle=> {:oracle_se1=>["li","byol"], :oracle_se=>["byol"], :oracle_ee=>["byol"]},
                           :sqlserver=> {:sqlserver_ex=>["li-ex"], :sqlserver_web=>["li-web"], :sqlserver_se=>["li-se","byol"], :sqlserver_ee=>["byol"]}
                          }

    
    def is_multi_az?(type)
      return true if type.match("multiAZ")
      false
    end

    def is_byol?(type)
      return true if type.match("byol")
      false
    end                                  

    def get_rds_on_demand_instance_pricing
      @@DB_TYPE.each do |db|
        @@OD_DB_DEPLOY_TYPE[db].each {|db_type, db_instances|
          db_instances.each do |dp_type|
            #
            # to find out the byol type
            is_byol = is_byol? dp_type

            if [:mysql, :postgresql, :oracle].include? db
              fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{dp_type}-deployments.json",:ondemand, db_type, is_byol)
            elsif db == :sqlserver
              fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/sqlserver-#{dp_type}-ondemand.json",:ondemand, db_type, is_byol)
            end
          end
        }
      end
    end

    def get_rds_reserved_instance_pricing
       @@DB_TYPE.each do |db|
        if [:mysql, :postgresql].include? db
          @@RES_TYPES.each do |res_type|
            if db == :postgresql and res_type == :heavy
              fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{res_type}-utilization-reserved-instances.json", res_type, db, false)
            elsif db == :mysql
              fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{res_type}-utilization-reserved-instances.json", res_type, db, false)
            end            
          end
        else
          @@RESERVED_DB_DEPLOY_TYPE[db].each {|db_type, db_instance|
            @@RES_TYPES.each do |res_type|
              db_instance.each do |dp_type|
                is_byol = is_byol? dp_type
                if db == :oracle
                  fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{dp_type}-#{res_type}-utilization-reserved-instances.json", res_type, db_type, is_byol) 
                elsif db == :sqlserver
                  fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/sqlserver-#{dp_type}-#{res_type}-ri.json", res_type, db_type, is_byol)
                end
              end    
            end            
          }
        end
      end
    end

    def fetch_on_demand_rds_instance_pricing(url, type_of_rds_instance, db_type, is_byol)
      res = fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['types'].each do |type|
          type['tiers'].each do |tier|
            begin
              #
              # this is special case URL, it is oracle - multiAZ type of deployment but it doesn't have mutliAZ attributes in json.
              if url == "http://aws.amazon.com/rds/pricing/oracle/pricing-li-multiAZ-deployments.json"
                is_multi_az = true
              else
                is_multi_az = is_multi_az? type["name"]
              end              
              api_name, name = RdsInstanceType.get_name(type["name"], tier["name"], type_of_rds_instance != :ondemand)
              
              region.add_or_update_rds_instance_type(api_name, name, db_type, type_of_rds_instance, tier, is_multi_az, is_byol)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end                        
      end
    end

    def fetch_reserved_rds_instance_pricing(url, type_of_rds_instance, db_type, is_byol)
      res = fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['instanceTypes'].each do |type|
          type['tiers'].each do |tier|
            begin
                is_multi_az = is_multi_az? type["type"]
                api_name, name = RdsInstanceType.get_name(type["type"], tier["size"], true)
                
                region.add_or_update_rds_instance_type(api_name, name, db_type, type_of_rds_instance, tier, is_multi_az, is_byol)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    end                              
  end
end