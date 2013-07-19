require 'json'
require 'net/http'

Dir[File.join(File.dirname(__FILE__), 'amazon-pricing/*.rb')].sort.each { |lib| require lib }

#--
# Amazon Web Services Pricing Ruby library
#
# Ruby Gem Name::  amazon-pricing
# Author::    Joe Kinsella (mailto:joe.kinsella@gmail.com)
# Copyright:: Copyright (c) 2011-2012 Sonian
# License::   Distributes under the same terms as Ruby
# Home::      http://github.com/sonian/amazon-pricing
#++
module AwsPricing

  # PriceList provides the primary interface for retrieving AWS pricing.
  # Upon instantiating a PriceList object, all the corresponding pricing
  # information will be retrieved from Amazon via currently undocumented
  # json APIs.
  class PriceList
    attr_accessor :regions, :version_ec2_on_demand_instance,
      :version_ec2_reserved_instance

    def initialize
      @_regions = {}
      get_ec2_on_demand_instance_pricing
      get_ec2_reserved_instance_pricing
      fetch_ec2_ebs_pricing
    end

    def get_region(name)
      @_regions[@@Region_Lookup[name] || name]
    end

    def regions
      @_regions.values
    end

    # Type = :on_demand or :reserved
    # reserved_usage_type = :light, :medium, :heavy
    def get_instance_type(region_name, type, api_name, reserved_usage_type = :medium)
      region = get_region(region_name)
      raise "Region #{region_name} not found" if region.nil?
      region.get_instance_type(type, api_name, reserved_usage_type)
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

    @@OS_TYPES = [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb]
    @@RES_TYPES = [:light, :medium, :heavy]

    def get_ec2_on_demand_instance_pricing
      @@OS_TYPES.each do |os|
        fetch_ec2_on_demand_instance_pricing(EC2_BASE_URL + "json/#{os}-od.json", os)
      end
    end

    def get_ec2_reserved_instance_pricing
      @@OS_TYPES.each do |os|
        @@RES_TYPES.each do |res_type|
          fetch_ec2_reserved_instance_pricing(EC2_BASE_URL + "json/#{os}-ri-#{res_type}.json", res_type, os)
        end
      end
    end

    # Retrieves the EC2 on-demand instance pricing.
    def fetch_ec2_on_demand_instance_pricing(url, platform)
      res = fetch_url(url)
      @version_ec2_on_demand_instance = res['vers']
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['instanceTypes'].each do |type|
          type['sizes'].each do |size|
            begin
              region.add_or_update_instance_type(:on_demand, InstanceType.new(region, type['type'], size, platform))
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    end
    # Retrieves the EC2 on-demand instance pricing.
    # reserved_usage_type = :light, :medium, :heavy
    def fetch_ec2_reserved_instance_pricing(url, reserved_usage_type, platform)
      res = fetch_url(url)
      @version_ec2_reserved_instance = res['vers']
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['instanceTypes'].each do |type|
          type['sizes'].each do |size|
            begin
              region.add_or_update_instance_type(:reserved, ReservedInstanceType.new(region, type['type'], size, reserved_usage_type, platform), reserved_usage_type)
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

    def fetch_url(url)
      uri = URI.parse(url)
      page = Net::HTTP.get_response(uri)
      JSON.parse(page.body)
    end

    EC2_BASE_URL = "http://aws.amazon.com/ec2/pricing/"

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