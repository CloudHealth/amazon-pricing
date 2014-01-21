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
    
    def initialize(region, api_name, name, json)
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

    def get_category_type(name, multi_az = false, byol = false)
      if multi_az == true and byol == true
        db = @category_types["#{name}_byol_multiaz"]
      elsif multi_az == true and byol == false
        db = @category_types["#{name}_multiaz"]
      elsif multi_az == false and byol == true
        db = @category_types["#{name}_byol"]
      else
        db = @category_types[name]
      end      
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def price_per_hour(category_type, type_of_instance, term = nil, is_multi_az = false, isByol = false)
      cat = get_category_type(category_type, is_multi_az, isByol)
      cat.price_per_hour(type_of_instance, term) unless cat.nil?      
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def prepay(category_type, type_of_instance, term = nil, is_multi_az = false, isByol = false)
      cat = get_category_type(category_type, is_multi_az, isByol)
      cat.prepay(type_of_instance, term) unless cat.nil?      
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def get_breakeven_month(category_types, type_of_instance, term, is_multi_az = false, isByol = false)
      cat = get_category_type(category_types, is_multi_az, isByol)
      cat.get_breakeven_month(type_of_instance, term) unless cat.nil?
    end

    def self.service_type(category)
      case category
        when 'os'; 'ec2'
        when 'db'; 'rds'
        else
          ''
      end
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
      'm3.medium' => 3750, 'm3.large' => 7500, 'm3.xlarge' => 15000, 'm3.2xlarge' => 30000,
      'c1.medium' => 1700, 'c1.xlarge' => 7000,
      'hi1.4xlarge' => 60500,
      'cg1.4xlarge' => 22000,
      'cc1.4xlarge' => 23000, 'cc2.8xlarge' => 60500,
      't1.micro' => 1700,
      'cr1.8xlarge' => 244000,
      'hs1.8xlarge' => 117000,
      'g2.2xlarge' => 15000,      
      'db.m1.small' => 1700, 'db.m1.medium' => 3750, 'db.m1.large' => 7500, 'db.m1.xlarge' => 15000,
      'db.m2.xlarge' => 17100, 'db.m2.2xlarge' => 34000, 'db.m2.4xlarge' => 68000, 'db.cr1.8xlarge' => 244000,
      'db.t1.micro' => 613,
      'c3.large' => 3750, 'c3.xlarge' => 7000, 'c3.2xlarge' => 15000, 'c3.4xlarge' => 30000, 'c3.8xlarge' => 60000, 
      'i2.large' => 15000, 'i2.xlarge' => 30500, 'i2.2xlarge' => 61000, 'i2.4xlarge' => 122000, 'i2.8xlarge' => 244000,
    }
    @@Disk_Lookup = {
      'm1.small' => 160, 'm1.medium' => 410, 'm1.large' =>850, 'm1.xlarge' => 1690,
      'm2.xlarge' => 420, 'm2.2xlarge' => 850, 'm2.4xlarge' => 1690,
      'm3.medium' => 4, 'm3.large' => 32, 'm3.xlarge' => 80, 'm3.2xlarge' => 160,
      'c1.medium' => 350, 'c1.xlarge' => 1690,
      'hi1.4xlarge' => 2048,
      'cg1.4xlarge' => 1690,
      'cc1.4xlarge' => 1690, 'cc2.8xlarge' => 3370,
      't1.micro' => 160,
      'cr1.8xlarge' => 240,
      'hs1.8xlarge' => 48000,
      'g2.2xlarge' => 60,      
      'db.m1.small' => 160, 'db.m1.medium' => 410, 'db.m1.large' =>850, 'db.m1.xlarge' => 1690,
      'db.m2.xlarge' => 420, 'db.m2.2xlarge' => 850, 'db.m2.4xlarge' => 1690, 'db.cr1.8xlarge' => 1690,
      'db.t1.micro' => 160,
      'c3.large' => 32, 'c3.xlarge' => 80, 'c3.2xlarge' => 160, 'c3.4xlarge' => 320, 'c3.8xlarge' => 640, 
      'i2.large' => 360, 'i2.xlarge' => 720, 'i2.2xlarge' => 1440, 'i2.4xlarge' => 2880, 'i2.8xlarge' => 5760,
    }
    @@Platform_Lookup = {
      'm1.small' => 32, 'm1.medium' => 32, 'm1.large' => 64, 'm1.xlarge' => 64,
      'm2.xlarge' => 64, 'm2.2xlarge' => 64, 'm2.4xlarge' => 64,
      'm3.medium' => 64, 'm3.large' => 64, 'm3.xlarge' => 64, 'm3.2xlarge' => 64,
      'c1.medium' => 32, 'c1.xlarge' => 64,
      'hi1.4xlarge' => 64,
      'cg1.4xlarge' => 64,
      'cc1.4xlarge' => 64, 'cc2.8xlarge' => 64,
      't1.micro' => 32,
      'cr1.8xlarge' => 64,
      'hs1.8xlarge' => 64,
      'g2.2xlarge' => 64,      
      'db.m1.small' => 64, 'db.m1.medium' => 64, 'db.m1.large' => 64, 'db.m1.xlarge' => 64,
      'db.m2.xlarge' => 64, 'db.m2.2xlarge' => 64, 'db.m2.4xlarge' => 64, 'db.cr1.8xlarge' => 64,
      'db.t1.micro' => 64,
      'c3.large' => 64, 'c3.xlarge' => 64, 'c3.2xlarge' => 64, 'c3.4xlarge' => 64, 'c3.8xlarge' => 64, 
      'i2.large' => 64, 'i2.xlarge' => 64, 'i2.2xlarge' => 64, 'i2.4xlarge' => 64, 'i2.8xlarge' => 64,
    }
    @@Compute_Units_Lookup = {
      'm1.small' => 1, 'm1.medium' => 2, 'm1.large' => 4, 'm1.xlarge' => 8,
      'm2.xlarge' => 6.5, 'm2.2xlarge' => 13, 'm2.4xlarge' => 26,
      'm3.medium' => 3, 'm3.large' => 6.5, 'm3.xlarge' => 13, 'm3.2xlarge' => 26,
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
      'db.m2.xlarge' => 6.5, 'db.m2.2xlarge' => 13, 'db.m2.4xlarge' => 26, 'db.cr1.8xlarge' => 88,
      'db.t1.micro' => 1,
      'c3.large' => 7, 'c3.xlarge' => 14, 'c3.2xlarge' => 28, 'c3.4xlarge' => 55, 'c3.8xlarge' => 108, 
      # Since I2 is not released, the cpmpute units are not yet published, so this is estimate
      'i2.large' => 6.5, 'i2.xlarge' => 13, 'i2.2xlarge' => 26, 'i2.4xlarge' => 52, 'i2.8xlarge' => 104,
    }
    @@Virtual_Cores_Lookup = {
      'm1.small' => 1, 'm1.medium' => 1, 'm1.large' => 2, 'm1.xlarge' => 4,
      'm2.xlarge' => 2, 'm2.2xlarge' => 4, 'm2.4xlarge' => 8,
      'm3.medium' => 1, 'm3.large' => 2, 'm3.xlarge' => 4, 'm3.2xlarge' => 8,
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
      'db.m2.xlarge' => 2, 'db.m2.2xlarge' => 4, 'db.m2.4xlarge' => 8, 'db.cr1.8xlarge' => 16,
      'db.t1.micro' => 0,
      'c3.large' => 2, 'c3.xlarge' => 4, 'c3.2xlarge' => 8, 'c3.4xlarge' => 16, 'c3.8xlarge' => 32, 
      'i2.large' => 2, 'i2.xlarge' => 4, 'i2.2xlarge' => 8, 'i2.4xlarge' => 16, 'i2.8xlarge' => 32,
    }
    @@Disk_Type_Lookup = {
      'm1.small' => :ephemeral, 'm1.medium' => :ephemeral, 'm1.large' => :ephemeral, 'm1.xlarge' => :ephemeral,
      'm2.xlarge' => :ephemeral, 'm2.2xlarge' => :ephemeral, 'm2.4xlarge' => :ephemeral,
      'm3.medium' => :ssd, 'm3.large' => :ssd, 'm3.xlarge' => :ssd, 'm3.2xlarge' => :ssd,
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
      'db.m2.xlarge' => :ephemeral, 'db.m2.2xlarge' => :ephemeral, 'db.m2.4xlarge' => :ephemeral, 'db.cr1.8xlarge' => :ephemeral,
      'db.t1.micro' => :ebs,
      'c3.large' => :ssd, 'c3.xlarge' => :ssd, 'c3.2xlarge' => :ssd, 'c3.4xlarge' => :ssd, 'c3.8xlarge' => :ssd, 
      'i2.large' => :ssd, 'i2.xlarge' => :ssd, 'i2.2xlarge' => :ssd, 'i2.4xlarge' => :ssd, 'i2.8xlarge' => :ssd,
    }
  end

end
