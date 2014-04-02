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

      @disk_in_gb = InstanceType.get_disk(api_name)
      @platform = InstanceType.get_platform(api_name)
      @disk_type = InstanceType.get_disk_type(api_name)
      @memory_in_mb = InstanceType.get_memory(api_name)
      @compute_units = InstanceType.get_compute_units(api_name)
      @virtual_cores = InstanceType.get_virtual_cores(api_name)
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

    def self.populate_lookups
      return unless @@Memory_Lookup.empty? && @@Compute_Units_Lookup.empty? && @@Virtual_Cores_Lookup.empty?

      res = AwsPricing::PriceList.fetch_url("http://aws-assets-pricing-prod.s3.amazonaws.com/pricing/ec2/linux-od.js")
      res['config']['regions'].each do |reg|
        reg['instanceTypes'].each do |type|
          items = type['sizes']
          items = [type] if items.nil?
          items.each do |size|
            begin
              api_name = size["size"]
              @@Memory_Lookup[api_name] = size["memoryGiB"].to_f * 1000
              @@Compute_Units_Lookup[api_name] = size["ECU"].to_i 
              @@Virtual_Cores_Lookup[api_name] = size["vCPU"].to_i 
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end

    end

    protected

    def self.get_disk(api_name)
      @@Disk_Lookup[api_name]
    end

    def self.get_platform(api_name)
      @@Platform_Lookup[api_name]
    end

    def self.get_disk_type(api_name)
      @@Disk_Type_Lookup[api_name]
    end

    def self.get_memory(api_name)
      @@Memory_Lookup[api_name]
    end

    def self.get_compute_units(api_name)
      @@Compute_Units_Lookup[api_name]
    end

    def self.get_virtual_cores(api_name)
      @@Virtual_Cores_Lookup[api_name]
    end

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

    @@Name_Lookup = {
      'm1.small' => 'Standard Small', 'm1.medium' => 'Standard Medium', 'm1.large' => 'Standard Large', 'm1.xlarge' => 'Standard Extra Large',
      'm2.xlarge' => 'Hi-Memory Extra Large', 'm2.2xlarge' => 'Hi-Memory Double Extra Large', 'm2.4xlarge' => 'Hi-Memory Quadruple Extra Large',
      'm3.medium' => 'M3 Medium Instance', 'm3.large'=>'M3 Large Instance', 'm3.xlarge' => 'M3 Extra Large Instance', 'm3.2xlarge' => 'M3 Double Extra Large Instance',
      'c1.medium' => 'High-CPU Medium', 'c1.xlarge' => 'High-CPU Extra Large',
      'hi1.4xlarge' => 'High I/O Quadruple Extra Large',
      'cg1.4xlarge' => 'Cluster GPU Quadruple Extra Large',
      'cc1.4xlarge' => 'Cluster Compute Quadruple Extra Large', 'cc2.8xlarge' => 'Cluster Compute Eight Extra Large',
      't1.micro' => 'Micro',
      'cr1.8xlarge' => 'High-Memory Cluster Eight Extra Large', 
      'hs1.8xlarge' => 'High-Storage Eight Extra Large',
      'g2.2xlarge' => 'Cluster GPU Double Extra Large',
      'c3.large' => 'High-Compute Large', 'c3.xlarge' => 'High-Compute Extra Large', 'c3.2xlarge' => 'High-Compute Double Extra Large', 'c3.4xlarge' => 'High-Compute Quadruple Extra Large', 'c3.8xlarge' => 'High-Compute Eight Extra Large',
      'i2.xlarge' => 'High I/O Extra Large', 'i2.2xlarge' => 'High I/O Double Extra Large', 'i2.4xlarge' => 'High I/O Quadruple Extra Large', 'i2.8xlarge' => 'High I/O Eight Extra Large',
      'r3.large' => 'Memory Optimized Large', 'r3.xlarge' => 'Memory Optimized Extra Large', 'r3.2xlarge' => 'Memory Optimized Double Extra Large', 'r3.4xlarge' => 'Memory Optimized Quadruple Extra Large', 'r3.8xlarge' => 'Memory Optimized Eight Extra Large',
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
      'r3.large' => 32, 'r3.xlarge' => 80, 'r3.2xlarge' => 160, 'r3.4xlarge' => 320, 'r3.8xlarge' => 640,
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
      'r3.large' => 64, 'r3.xlarge' => 64, 'r3.2xlarge' => 64, 'r3.4xlarge' => 64, 'r3.8xlarge' => 64,
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
      # Remove asterisk when this is released instance type
      #'r3.large *' => :ssd, 'r3.xlarge *' => :ssd, 'r3.2xlarge *' => :ssd, 'r3.4xlarge *' => :ssd, 'r3.8xlarge *' => :ssd,
    }

    # Due to fact AWS pricing API only reports these for EC2, we will fetch from EC2 and keep around for lookup
    # e.g. EC2 = http://aws-assets-pricing-prod.s3.amazonaws.com/pricing/ec2/linux-od.js
    # e.g. RDS = http://aws-assets-pricing-prod.s3.amazonaws.com/pricing/rds/mysql/pricing-standard-deployments.js
    @@Memory_Lookup = {}
    @@Compute_Units_Lookup = {}
    @@Virtual_Cores_Lookup = {}

  end

end
