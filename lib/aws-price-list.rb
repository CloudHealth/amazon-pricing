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

    def get_instance_types
      instance_types = []
      @_regions.each do |region|
        region.ec2_instance_types.each do |instance_type|
          instance_types << instance_type
        end
      end
      instance_types
    end

    def get_instance_type(region_name, api_name)
      region = get_region(region_name)
      raise "Region #{region_name} not found" if region.nil?
      region.get_instance_type(api_name)
    end

    def self.fetch_url(url)
      uri = URI.parse(url)
      page = Net::HTTP.get_response(uri)
      # Now that AWS switched from json to jsonp, remove first/last lines
      body = page.body.gsub("callback(", "").reverse.sub(")", "").reverse
      if body.split("\n").last == ";"
        # Now remove one more line (rds is returning ";", ec2 empty line)
        body = body.reverse.sub(";", "").reverse
      elsif body[-1] == ";"
        body.chop!
      end

      begin
        JSON.parse(body)
      rescue JSON::ParserError
        # Handle "json" with keys that are not quoted
        # When we get {foo: "1"} instead of {"foo": "1"}
        # http://stackoverflow.com/questions/2060356/parsing-json-without-quoted-keys
        JSON.parse(body.gsub(/(\w+)\s*:/, '"\1":'))
      end
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

    EC2_BASE_URL = "http://a0.awsstatic.com/pricing/1/ec2/"
    EBS_BASE_URL = "http://a0.awsstatic.com/pricing/1/ebs/"
    RDS_BASE_URL = "http://a0.awsstatic.com/pricing/1/rds/"

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