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
    end

    def get_region(name)
      @_regions[@@Region_Lookup[name] || name]
    end

    def regions
      @_regions.values
    end

    # Type = :on_demand or :reserved
    # reserved_usage_type = :light, :medium, :heavy
    def get_instance_type(availability_zone, type, api_name, reserved_usage_type = :medium)
      region_name = @@Availability_Zone_Lookup[availability_zone]
      raise "Region not found for availability zone #{availability_zone}" if region_name.nil?
      region = get_region(region_name)
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

    # Retrieves the EC2 on-demand instance pricing.
    def get_ec2_on_demand_instance_pricing
      uri = URI.parse(EC2_STANDARD_INSTANCE_PRICING_URL)
      page = Net::HTTP.get_response(uri)
      res = JSON.parse(page.body)
      @version_ec2_on_demand_instance = res['vers']
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['instanceTypes'].each do |type|
          type['sizes'].each do |size|
            region.add_instance_type(:on_demand, InstanceType.new(region, type['type'], size))
          end
        end
      end
    end

    def get_ec2_reserved_instance_pricing
      fetch_ec2_reserved_instance_pricing(EC2_RESERVED_INSTANCE_LIGHT_PRICING_URL, :low)
      fetch_ec2_reserved_instance_pricing(EC2_RESERVED_INSTANCE_MEDIUM_PRICING_URL, :medium)
      fetch_ec2_reserved_instance_pricing(EC2_RESERVED_INSTANCE_HEAVY_PRICING_URL, :heavy)
    end

    # Retrieves the EC2 on-demand instance pricing.
    # reserved_usage_type = :light, :medium, :heavy
    def fetch_ec2_reserved_instance_pricing(url, reserved_usage_type)
      uri = URI.parse(url)
      page = Net::HTTP.get_response(uri)
      res = JSON.parse(page.body)
      @version_ec2_reserved_instance = res['vers']
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['instanceTypes'].each do |type|
          type['sizes'].each do |size|
            region.add_instance_type(:reserved, ReservedInstanceType.new(region, type['type'], size), reserved_usage_type)
          end
        end
      end
    end

    EC2_STANDARD_INSTANCE_PRICING_URL = 'http://aws.amazon.com/ec2/pricing/pricing-on-demand-instances.json'
    EC2_RESERVED_INSTANCE_LIGHT_PRICING_URL = 'http://aws.amazon.com/ec2/pricing/pricing-reserved-instances-low-utilization.json'
    EC2_RESERVED_INSTANCE_MEDIUM_PRICING_URL = 'http://aws.amazon.com/ec2/pricing/pricing-reserved-instances.json'
    EC2_RESERVED_INSTANCE_HEAVY_PRICING_URL = 'http://aws.amazon.com/ec2/pricing/pricing-reserved-instances-high-utilization.json'

    @@Availability_Zone_Lookup = {
      'us-east-1a' => 'us-east', 'us-east-1b' => 'us-east', 'us-east-1c' => 'us-east',
      'us-east-1d' => 'us-east', 'us-east-1e' => 'us-east', 'us-west-1a' => 'us-west',
      'us-west-1b' => 'us-west', 'us-west-1c' => 'us-west', 'us-west-2a' => 'us-west-2',
      'us-west-2b' => 'us-west-2', 'eu-west-1a' => 'eu-ireland', 'eu-west-1b' => 'eu-ireland',
      'eu-west-1c' => 'eu-ireland', 'ap-southeast-1a' => 'apac-sin', 'ap-southeast-1b' => 'apac-sin',
      'ap-northeast-1a' => 'apac-tokyo', 'ap-northeast-1b' => 'apac-tokyo', 'sa-east-1a' => 'sa-east-1',
      'sa-east-1b' => 'sa-east-1'
    }
    
    @@Region_Lookup = {
      'us-east-1' => 'us-east',
      'us-west-1' => 'us-west',
      'us-west-2' => 'us-west-2',
      'eu-west-1' => 'eu-ireland',
      'ap-southeast-1' => 'apac-sin', 
      'ap-northeast-1' => 'apac-tokyo', 
      'sa-east-1' => 'sa-east-1'
    }
  end
end