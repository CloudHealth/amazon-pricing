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

  class UnknownTypeError < NameError
  end

  # InstanceType is a specific type of instance in a region with a defined
  # price per hour. The price will vary by platform (Linux, Windows).
  #
  # e.g. m1.large instance in US-East region will cost $0.34/hour for Linux and
  # $0.48/hour for Windows.
  #
  class InstanceType
    attr_accessor :name, :api_name, :memory_in_mb, :platform, :compute_units, :virtual_cores, :disk_type, :disk_in_gb
    
    def initialize(region, api_name, name)
      @category_types = {}

      @region = region
      @name = name
      @api_name = api_name

      @memory_in_mb = @@Memory_Lookup[@api_name]
      @disk_in_gb = @@Disk_Lookup[@api_name]
      @platform = @@Platform_Lookup[@api_name]
      @compute_units = @@Compute_Units_Lookup[@api_name]
      @virtual_cores = @@Virtual_Cores_Lookup[@api_name]
      @disk_type = @@Disk_Type_Lookup[@api_name]
    end

    # Keep this in for backwards compatibility within current major version of gem
    def disk_in_mb
      @disk_in_gb * 1000
    end

    def memory_in_gb
      @memory_in_mb / 1000
    end

    def category_types
      @category_types.values
    end

    def get_category_type(name, multiAz = false, byol = false)
      if multiAz == true and byol == true
        db = @category_types["#{name}_byol_multiAz"]
      elsif multiAz == true and byol == false
        db = @category_types["#{name}_multiAz"]
      elsif multiAz == false and byol == true
        db = @category_types["#{name}_byol"]
      else
        db = @category_types[name]
      end      
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def price_per_hour(category_type, type_of_instance, term = nil, isMultiAz = false, isByol = false)
      cat = get_category_type(category_type, isMultiAz, isByol)
      cat.price_per_hour(type_of_instance, term) unless cat.nil?      
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def prepay(category_type, type_of_instance, term = nil, isMultiAz = false, isByol = false)
      cat = get_category_type(category_type, isMultiAz, isByol)
      cat.prepay(type_of_instance, term) unless cat.nil?      
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def get_breakeven_month(category_types, type_of_instance, term)
      os = get_category_type(category_types)
      os.get_breakeven_month(type_of_instance, term)
    end

    protected

    def coerce_price(price)
      return nil if price.nil? || price == "N/A"
      price.gsub(",","").to_f
    end

    def self.get_values(json, category_type)
      values = {}
      unless json['valueColumns'].nil?
        json['valueColumns'].each do |val|
          values[val['name']] = val['prices']['USD']
        end
      else
        values[category_type.to_s] = json['prices']['USD']
      end
      values
    end

    @@Memory_Lookup = {
      'm1.small' => 1700, 'm1.medium' => 3750, 'm1.large' => 7500, 'm1.xlarge' => 15000,
      'm2.xlarge' => 17100, 'm2.2xlarge' => 34200, 'm2.4xlarge' => 68400,
      'm3.xlarge' => 15000, 'm3.2xlarge' => 30000,
      'c1.medium' => 1700, 'c1.xlarge' => 7000,
      'hi1.4xlarge' => 60500,
      'cg1.4xlarge' => 22000,
      'cc1.4xlarge' => 23000, 'cc2.8xlarge' => 60500,
      't1.micro' => 1700,
      'm3.xlarge' => 15000, 'm3.xlarge' => 30000,
      'cr1.8xlarge' => 244000,
      'hs1.8xlarge' => 117000,
      'g2.2xlarge' => 15000,
      'db.m1.small' => 1700, 'db.m1.medium' => 3750, 'db.m1.large' => 7500, 'db.m1.xlarge' => 15000,
      'db.m2.xlarge' => 17100, 'db.m2.2xlarge' => 34200, 'db.m2.4xlarge' => 68400, 'db.m2.8xlarge' => 136800,
      'db.t1.micro' => 1700,
    }
    @@Disk_Lookup = {
      'm1.small' => 160, 'm1.medium' => 410, 'm1.large' =>850, 'm1.xlarge' => 1690,
      'm2.xlarge' => 420, 'm2.2xlarge' => 850, 'm2.4xlarge' => 1690,
      'm3.xlarge' => 0, 'm3.2xlarge' => 0,
      'c1.medium' => 350, 'c1.xlarge' => 1690,
      'hi1.4xlarge' => 2048,
      'cg1.4xlarge' => 1690,
      'cc1.4xlarge' => 1690, 'cc2.8xlarge' => 3370,
      't1.micro' => 160,
      'm3.xlarge' => 0, 'm3.xlarge' => 0,
      'cr1.8xlarge' => 240,
      'hs1.8xlarge' => 48000,
      'g2.2xlarge' => 60,
      'db.m1.small' => 160, 'db.m1.medium' => 410, 'db.m1.large' =>850, 'db.m1.xlarge' => 1690,
      'db.m2.xlarge' => 420, 'db.m2.2xlarge' => 850, 'db.m2.4xlarge' => 1690, 'db.m2.8xlarge' => 0,
      'db.t1.micro' => 160,
    }
    @@Platform_Lookup = {
      'm1.small' => 32, 'm1.medium' => 32, 'm1.large' => 64, 'm1.xlarge' => 64,
      'm2.xlarge' => 64, 'm2.2xlarge' => 64, 'm2.4xlarge' => 64,
      'm3.xlarge' => 64, 'm3.2xlarge' => 64,
      'c1.medium' => 32, 'c1.xlarge' => 64,
      'hi1.4xlarge' => 64,
      'cg1.4xlarge' => 64,
      'cc1.4xlarge' => 64, 'cc2.8xlarge' => 64,
      't1.micro' => 32,
      'm3.xlarge' => 64, 'm3.xlarge' => 64,
      'cr1.8xlarge' => 64,
      'hs1.8xlarge' => 64,
      'g2.2xlarge' => 64,
      'db.m1.small' => 32, 'db.m1.medium' => 32, 'db.m1.large' => 64, 'db.m1.xlarge' => 64,
      'db.m2.xlarge' => 64, 'db.m2.2xlarge' => 64, 'db.m2.4xlarge' => 64, 'db.m2.8xlarge' => 64,
      'db.t1.micro' => 32,
    }
    @@Compute_Units_Lookup = {
      'm1.small' => 1, 'm1.medium' => 2, 'm1.large' => 4, 'm1.xlarge' => 8,
      'm2.xlarge' => 6, 'm2.2xlarge' => 13, 'm2.4xlarge' => 26,
      'm3.xlarge' => 13, 'm3.2xlarge' => 26,
      'c1.medium' => 5, 'c1.xlarge' => 20,
      'hi1.4xlarge' => 35,
      'cg1.4xlarge' => 34,
      'cc1.4xlarge' => 34, 'cc2.8xlarge' => 88,
      't1.micro' => 2,
      'cr1.8xlarge' => 88,
      'hs1.8xlarge' => 35,
      'g2.2xlarge' => 26,
      'unknown' => 0,
      'db.m1.small' => 1, 'db.m1.medium' => 2, 'db.m1.large' => 4, 'db.m1.xlarge' => 8,
      'db.m2.xlarge' => 6, 'db.m2.2xlarge' => 13, 'db.m2.4xlarge' => 26, 'db.m2.8xlarge' => 52,
      'db.t1.micro' => 2,
    }
    @@Virtual_Cores_Lookup = {
      'm1.small' => 1, 'm1.medium' => 1, 'm1.large' => 2, 'm1.xlarge' => 4,
      'm2.xlarge' => 2, 'm2.2xlarge' => 4, 'm2.4xlarge' => 8,
      'm3.xlarge' => 4, 'm3.2xlarge' => 8,
      'c1.medium' => 2, 'c1.xlarge' => 8,
      'hi1.4xlarge' => 16,
      'cg1.4xlarge' => 8,
      'cc1.4xlarge' => 8, 'cc2.8xlarge' => 16,
      't1.micro' => 0,
      'cr1.8xlarge' => 16,
      'hs1.8xlarge' => 16,
      'g2.2xlarge' => 8,
      'unknown' => 0,
      'db.m1.small' => 1, 'db.m1.medium' => 1, 'db.m1.large' => 2, 'db.m1.xlarge' => 4,
      'db.m2.xlarge' => 2, 'db.m2.2xlarge' => 4, 'db.m2.4xlarge' => 8, 'db.m2.8xlarge' => 16,
      'db.t1.micro' => 0,
    }
    @@Disk_Type_Lookup = {
      'm1.small' => :ephemeral, 'm1.medium' => :ephemeral, 'm1.large' => :ephemeral, 'm1.xlarge' => :ephemeral,
      'm2.xlarge' => :ephemeral, 'm2.2xlarge' => :ephemeral, 'm2.4xlarge' => :ephemeral,
      'm3.xlarge' => :ephemeral, 'm3.2xlarge' => :ephemeral,
      'c1.medium' => :ephemeral, 'c1.xlarge' => :ephemeral,
      'hi1.4xlarge' => :ssd,
      'cg1.4xlarge' => :ephemeral,
      'cc1.4xlarge' => :ephemeral, 'cc2.8xlarge' => :ephemeral,
      't1.micro' => :ebs,
      'cr1.8xlarge' => :ssd,
      'hs1.8xlarge' => :ephemeral,
      'g2.2xlarge' => :ssd,
      'unknown' => :ephemeral,
      'db.m1.small' => :ephemeral, 'db.m1.medium' => :ephemeral, 'db.m1.large' => :ephemeral, 'db.m1.xlarge' => :ephemeral,
      'db.m2.xlarge' => :ephemeral, 'db.m2.2xlarge' => :ephemeral, 'db.m2.4xlarge' => :ephemeral, 'db.m2.8xlarge' => :ephemeral,
      'db.t1.micro' => :ebs,
    }
  end

end
