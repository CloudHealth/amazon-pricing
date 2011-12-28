require 'json'
require 'net/http'

Dir[File.join(File.dirname(__FILE__), 'aws-pricing/*.rb')].sort.each { |lib| require lib }

#--
# Amazon Web Services Pricing Ruby library
#
# Ruby Gem Name::  aws-pricing
# Author::    Joe Kinsella (mailto:joe.kinsella@gmail.com)
# Copyright:: Copyright (c) 2011-2012 Sonian
# License::   Distributes under the same terms as Ruby
# Home::      http://github.com/sonian/aws-pricing
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
      @_regions[name]
    end

    def regions
      @_regions.values
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

    # Retrieves the EC2 on-demand instance pricing.
    def get_ec2_reserved_instance_pricing
      uri = URI.parse(EC2_RESERVED_INSTANCE_PRICING_URL)
      page = Net::HTTP.get_response(uri)
      res = JSON.parse(page.body)
      @version_ec2_reserved_instance = res['vers']
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['instanceTypes'].each do |type|
          type['sizes'].each do |size|
            region.add_instance_type(:reserved, ReservedInstanceType.new(region, type['type'], size))
          end
        end
      end
    end

    EC2_STANDARD_INSTANCE_PRICING_URL = 'http://aws.amazon.com/ec2/pricing/pricing-on-demand-instances.json'
    EC2_RESERVED_INSTANCE_PRICING_URL = 'http://aws.amazon.com/ec2/pricing/pricing-reserved-instances.json'

  end
end