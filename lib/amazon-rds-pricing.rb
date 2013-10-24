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
  class RdsPriceList
    attr_accessor :regions

    def initialize
      @_regions = {}
      get_rds_on_demand_instance_pricing
      get_rds_reserved_instance_pricing
    end

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

    protected

    @@DB_TYPE = [:mysql, :oracle, :sqlserver]
    @@ON_DEMAND_RDS_DB_INSTANCES = {
                                  :mysql=>["standard","multiAZ"], 
                                  :oracle=>["li-standard","byol-standard","li-multiAZ","byol-multiAZ"],
                                  :sqlserver=>["li-ex","li-web","li-se","byol"]
                                }

    @@RESERVED_RDS_DB_INSTANCES = {
                                  :oracle=>['li','byol'],
                                  :sqlserver=>['li-ex','li-web','li-se','byol']  
                                }                                
    
    @@RES_TYPES = [:light, :medium, :heavy]
    
    def get_rds_on_demand_instance_pricing
      @@DB_TYPE.each do |db_type|
        @@ON_DEMAND_RDS_DB_INSTANCES[db_type].each do |on_demand_list|
          if db_type == :mysql or db_type == :oracle
            fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db_type}/pricing-#{on_demand_list}-deployments.json",:ondemand,db_type)  
          elsif db_type == :sqlserver
            fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db_type}/sqlserver-#{on_demand_list}-ondemand.json",:ondemand,db_type)
          end
        end
      end
    end

    def get_rds_reserved_instance_pricing
       @@DB_TYPE.each do |db_type|
         @@RES_TYPES.each do |res_type|
            if db_type == :mysql
              fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db_type}/pricing-#{res_type}-utilization-reserved-instances.json", res_type, db_type)              
            elsif db_type == :oracle or :sqlserver
              @@RESERVED_RDS_DB_INSTANCES[db_type].each do |reserved_list|
                fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db_type}/pricing-#{reserved_list}-#{res_type}-utilization-reserved-instances.json", res_type, db_type) if db_type == :oracle
                fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db_type}/sqlserver-#{reserved_list}-#{res_type}-ri.json", res_type, db_type) if db_type == :sqlserver
              end
            end
          end 
         end           
    end

    def fetch_on_demand_rds_instance_pricing(url, type_of_rds_instance, db_type)
      res = fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['types'].each do |type|
          type['tiers'].each do |tier|
            begin
                api_name, name = RdsInstanceType.get_name(type["name"], tier["name"], type_of_rds_instance != :ondemand)
                region.add_or_update_rds_instance_type(api_name, name, db_type, type_of_rds_instance, tier)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    end

    def fetch_reserved_rds_instance_pricing(url, type_of_rds_instance, db_type)
      res = fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['instanceTypes'].each do |type|
          type['tiers'].each do |tier|
            begin
                api_name, name = RdsInstanceType.get_name(type["type"], tier["size"], true)
                region.add_or_update_rds_instance_type(api_name, name, db_type, type_of_rds_instance, tier)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    end

    def fetch_url(url)
      uri = URI.parse(url)
      page = Net::HTTP.get_response(uri)
      JSON.parse(page.body)
    end
   
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
end