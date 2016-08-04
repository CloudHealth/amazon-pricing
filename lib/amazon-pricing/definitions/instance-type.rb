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
        when 'cache'; 'elasticache'
        else
          ''
      end
    end

    def self.populate_lookups
      # We use Linux on-demand to populate the lookup tables with the basic lookup information
      ["http://a0.awsstatic.com/pricing/1/ec2/linux-od.min.js", "http://a0.awsstatic.com/pricing/1/ec2/previous-generation/linux-od.min.js"].each do |url|
        res = AwsPricing::PriceList.fetch_url(url)

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
                $stderr.puts "[populate_lookups] WARNING: encountered #{$!.message}"
              end
            end
          end
        end
      end
    end

    # Returns the bytes/s capacity if defined, `nil` otherwise
    def self.disk_bytes_per_sec_capacity(api_name)
      if PER_SEC_CAPACITIES[api_name]
        PER_SEC_CAPACITIES[api_name][0] * 1024 * 1024
      end
    end

    # Returns the ops/s capacity if defined, `nil` otherwise
    def self.disk_ops_per_sec_capacity(api_name)
      if PER_SEC_CAPACITIES[api_name]
        PER_SEC_CAPACITIES[api_name][1]
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
      return nil if price.nil? || price.upcase == "N/A"
      price.gsub(",","").gsub("$", "").to_f
    end

    def self.get_values(json, category_type, override_price = false)
      values = {}
      unless json['valueColumns'].nil?
        json['valueColumns'].each do |val|
          values[val['name']] = val['prices']['USD']
          # AWS has data entry errors where you go to a windows pricing URL (e.g. http://a0.awsstatic.com/pricing/1/ec2/mswin-od.min.js)
          # but get a value for on-demand other than mswin
          values[category_type.to_s] = val['prices']['USD'] if override_price
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
      'm4.large' => 'M4 Large Instance', 'm4.xlarge' => 'M4 Extra Large Instance', 'm4.2xlarge' => 'M4 Double Extra Large Instance', 'm4.4xlarge' => 'M4 Quadruple Extra Large Instance', 'm4.10xlarge' => 'M4 Decuple Extra Large Instance',
      'c1.medium' => 'High-CPU Medium', 'c1.xlarge' => 'High-CPU Extra Large',
      'hi1.4xlarge' => 'High I/O Quadruple Extra Large',
      'cg1.4xlarge' => 'Cluster GPU Quadruple Extra Large',
      'cc1.4xlarge' => 'Cluster Compute Quadruple Extra Large', 'cc2.8xlarge' => 'Cluster Compute Eight Extra Large',
      't1.micro' => 'Micro',
      'cr1.8xlarge' => 'High-Memory Cluster Eight Extra Large',
      'hs1.8xlarge' => 'High-Storage Eight Extra Large',
      'g2.2xlarge' => 'Cluster GPU Double Extra Large', 'g2.8xlarge' => 'Cluster GPU Eight Extra Large',
      'c3.large' => 'High-Compute Large', 'c3.xlarge' => 'High-Compute Extra Large', 'c3.2xlarge' => 'High-Compute Double Extra Large', 'c3.4xlarge' => 'High-Compute Quadruple Extra Large', 'c3.8xlarge' => 'High-Compute Eight Extra Large',
      'i2.xlarge' => 'High I/O Extra Large', 'i2.2xlarge' => 'High I/O Double Extra Large', 'i2.4xlarge' => 'High I/O Quadruple Extra Large', 'i2.8xlarge' => 'High I/O Eight Extra Large',
      'd2.xlarge' => 'Dense Storage Extra Large', 'd2.2xlarge' => 'Dense Storage Double Extra Large', 'd2.4xlarge' => 'Dense Storage Quadruple Extra Large', 'd2.8xlarge' => 'Dense Storage Eight Extra Large',
      'r3.large' => 'Memory Optimized Large', 'r3.xlarge' => 'Memory Optimized Extra Large', 'r3.2xlarge' => 'Memory Optimized Double Extra Large', 'r3.4xlarge' => 'Memory Optimized Quadruple Extra Large', 'r3.8xlarge' => 'Memory Optimized Eight Extra Large',
      't2.nano' => 'Burstable Performance Instance Nano', 't2.micro' => 'Burstable Performance Instance Micro', 't2.small' => 'Burstable Performance Instance Small', 't2.medium' => 'Burstable Performance Instance Medium', 't2.large' => 'Burstable Performance Instance Large',
      'c4.large' => 'Compute Optimized Large', 'c4.xlarge' => 'Compute Optimized Extra Large', 'c4.2xlarge' => 'Compute Optimized Double Extra Large', 'c4.4xlarge' => 'Compute Optimized Quadruple Extra Large', 'c4.8xlarge' => 'Compute Optimized Eight Extra Large',
      'x1.32xlarge' => 'Memory Optimized Large-scale Enterprise-class',
    }
    @@Disk_Lookup = {
      'm1.small' => 160, 'm1.medium' => 410, 'm1.large' =>850, 'm1.xlarge' => 1690,
      'm2.xlarge' => 420, 'm2.2xlarge' => 850, 'm2.4xlarge' => 1690,
      'm3.medium' => 4, 'm3.large' => 32, 'm3.xlarge' => 80, 'm3.2xlarge' => 160,
      'm4.large' => 0, 'm4.xlarge' => 0, 'm4.2xlarge' => 0, 'm4.4xlarge' => 0, 'm4.10xlarge' => 0,
      'c1.medium' => 350, 'c1.xlarge' => 1690,
      'hi1.4xlarge' => 2048,
      'cg1.4xlarge' => 1690,
      'cc1.4xlarge' => 1690, 'cc2.8xlarge' => 3370,
      't1.micro' => 160,
      'cr1.8xlarge' => 240,
      'hs1.8xlarge' => 48000,
      'g2.2xlarge' => 60, 'g2.8xlarge' => 240,
      'db.m1.small' => 160, 'db.m1.medium' => 410, 'db.m1.large' =>850, 'db.m1.xlarge' => 1690,
      'db.m2.xlarge' => 420, 'db.m2.2xlarge' => 850, 'db.m2.4xlarge' => 1690, 'db.cr1.8xlarge' => 1690,
      'db.t1.micro' => 160,
      'c3.large' => 32, 'c3.xlarge' => 80, 'c3.2xlarge' => 160, 'c3.4xlarge' => 320, 'c3.8xlarge' => 640,
      'i2.large' => 360, 'i2.xlarge' => 720, 'i2.2xlarge' => 1440, 'i2.4xlarge' => 2880, 'i2.8xlarge' => 5760,
      'd2.xlarge' => 6000, 'd2.2xlarge' => 12000, 'd2.4xlarge' => 24000, 'd2.8xlarge' => 48000,
      'r3.large' => 32, 'r3.xlarge' => 80, 'r3.2xlarge' => 160, 'r3.4xlarge' => 320, 'r3.8xlarge' => 640,
      't2.nano' => 0, 't2.micro' => 0, 't2.small' => 0, 't2.medium' => 0, 't2.large' => 0,
      'c4.large' => 0, 'c4.xlarge' => 0, 'c4.2xlarge' => 0, 'c4.4xlarge' => 0, 'c4.8xlarge' => 0,
      'x1.32xlarge' => 3840,
    }
    @@Platform_Lookup = {
      'm1.small' => 32, 'm1.medium' => 32, 'm1.large' => 64, 'm1.xlarge' => 64,
      'm2.xlarge' => 64, 'm2.2xlarge' => 64, 'm2.4xlarge' => 64,
      'm3.medium' => 64, 'm3.large' => 64, 'm3.xlarge' => 64, 'm3.2xlarge' => 64,
      'm4.large' => 64, 'm4.xlarge' => 64, 'm4.2xlarge' => 64, 'm4.4xlarge' => 64, 'm4.10xlarge' => 64,
      'c1.medium' => 32, 'c1.xlarge' => 64,
      'hi1.4xlarge' => 64,
      'cg1.4xlarge' => 64,
      'cc1.4xlarge' => 64, 'cc2.8xlarge' => 64,
      't1.micro' => 32,
      'cr1.8xlarge' => 64,
      'hs1.8xlarge' => 64,
      'g2.2xlarge' => 64, 'g2.8xlarge' => 64,
      'db.m1.small' => 64, 'db.m1.medium' => 64, 'db.m1.large' => 64, 'db.m1.xlarge' => 64,
      'db.m2.xlarge' => 64, 'db.m2.2xlarge' => 64, 'db.m2.4xlarge' => 64, 'db.cr1.8xlarge' => 64,
      'db.t1.micro' => 64,
      'c3.large' => 64, 'c3.xlarge' => 64, 'c3.2xlarge' => 64, 'c3.4xlarge' => 64, 'c3.8xlarge' => 64,
      'i2.large' => 64, 'i2.xlarge' => 64, 'i2.2xlarge' => 64, 'i2.4xlarge' => 64, 'i2.8xlarge' => 64,
      'd2.xlarge' => 64, 'd2.2xlarge' => 64, 'd2.4xlarge' => 64, 'd2.8xlarge' => 64,
      'r3.large' => 64, 'r3.xlarge' => 64, 'r3.2xlarge' => 64, 'r3.4xlarge' => 64, 'r3.8xlarge' => 64,
      't2.nano' => 64, 't2.micro' => 64, 't2.small' => 64, 't2.medium' => 64, 't2.large' => 64,
      'c4.large' => 64, 'c4.xlarge' => 64, 'c4.2xlarge' => 64, 'c4.4xlarge' => 64, 'c4.8xlarge' => 64,
      'x1.32xlarge' => 64,
    }
    @@Disk_Type_Lookup = {
      'm1.small' => :ephemeral, 'm1.medium' => :ephemeral, 'm1.large' => :ephemeral, 'm1.xlarge' => :ephemeral,
      'm2.xlarge' => :ephemeral, 'm2.2xlarge' => :ephemeral, 'm2.4xlarge' => :ephemeral,
      'm3.medium' => :ssd, 'm3.large' => :ssd, 'm3.xlarge' => :ssd, 'm3.2xlarge' => :ssd,
      'm4.large' => :ebs, 'm4.xlarge' => :ebs, 'm4.2xlarge' => :ebs, 'm4.4xlarge' => :ebs, 'm4.10xlarge' => :ebs,
      'c1.medium' => :ephemeral, 'c1.xlarge' => :ephemeral,
      'hi1.4xlarge' => :ssd,
      'cg1.4xlarge' => :ephemeral,
      'cc1.4xlarge' => :ephemeral, 'cc2.8xlarge' => :ephemeral,
      't1.micro' => :ebs,
      'cr1.8xlarge' => :ssd,
      'hs1.8xlarge' => :ephemeral,
      'g2.2xlarge' => :ssd, 'g2.8xlarge' => :ssd,
      'unknown' => :ephemeral,
      'db.m1.small' => :ephemeral, 'db.m1.medium' => :ephemeral, 'db.m1.large' => :ephemeral, 'db.m1.xlarge' => :ephemeral,
      'db.m2.xlarge' => :ephemeral, 'db.m2.2xlarge' => :ephemeral, 'db.m2.4xlarge' => :ephemeral, 'db.cr1.8xlarge' => :ephemeral,
      'db.t1.micro' => :ebs,
      'c3.large' => :ssd, 'c3.xlarge' => :ssd, 'c3.2xlarge' => :ssd, 'c3.4xlarge' => :ssd, 'c3.8xlarge' => :ssd,
      'i2.large' => :ssd, 'i2.xlarge' => :ssd, 'i2.2xlarge' => :ssd, 'i2.4xlarge' => :ssd, 'i2.8xlarge' => :ssd,
      'd2.xlarge' => :ephemeral, 'd2.2xlarge' => :ephemeral, 'd2.4xlarge' => :ephemeral, 'd2.8xlarge' => :ephemeral,
      'r3.large' => :ssd, 'r3.xlarge' => :ssd, 'r3.2xlarge' => :ssd, 'r3.4xlarge' => :ssd, 'r3.8xlarge' => :ssd,
      't2.nano' => :ebs, 't2.micro' => :ebs, 't2.small' => :ebs, 't2.medium' => :ebs, 't2.large' => :ebs,
      'c4.large' => :ebs, 'c4.xlarge' => :ebs, 'c4.2xlarge' => :ebs, 'c4.4xlarge' => :ebs, 'c4.8xlarge' => :ebs,
      'x1.32xlarge' => :ssd,
    }

    # NOTE: These are populated by "populate_lookups"
    #       But... AWS does not always provide memory info (e.g. t2, r3, cache.*), so those are hardcoded below
    @@Memory_Lookup = {
      'cache.r3.large' => 13500, 'cache.r3.xlarge' => 28400, 'cache.r3.2xlarge' => 58200, 'cache.r3.4xlarge' => 118000, 'cache.r3.8xlarge' => 237000,
      'r3.large' => 15250, 'r3.xlarge' => 30500, 'r3.2xlarge' => 61000, 'r3.4xlarge' => 122000, 'r3.8xlarge' => 244000,
      'cache.m3.medium' => 2780, 'cache.m3.large' => 6050, 'cache.m3.xlarge' => 13300, 'cache.m3.2xlarge' => 27900,
      't2.nano' => 500, 't2.micro' => 1000, 't2.small' => 2000, 't2.medium' => 4000, 't2.large' => 8000,
      'cache.t2.micro' => 555, 'cache.t2.small' =>  1550, 'cache.t2.medium' => 3220,
      'cache.m1.small' => 1300, 'cache.m1.medium' => 3350, 'cache.m1.large' => 7100, 'cache.m1.xlarge' => 14600,
      'cache.m2.xlarge' => 16700, 'cache.m2.2xlarge' => 33800, 'cache.m2.4xlarge' => 68000,
      'cache.c1.xlarge' => 6600,
      'cache.t1.micro' => 213,
    }
    @@Virtual_Cores_Lookup = {
      'r3.large' => 2, 'r3.xlarge' => 4, 'r3.2xlarge' => 8, 'r3.4xlarge' => 16, 'r3.8xlarge' => 32,
      't2.nano' => 1, 't2.micro' => 1, 't2.small' => 1, 't2.medium' => 2, 't2.large' => 2,
    }

    # Due to fact AWS pricing API only reports these for EC2, we will fetch from EC2 and keep around for lookup
    # e.g. EC2 = http://aws-assets-pricing-prod.s3.amazonaws.com/pricing/ec2/linux-od.js
    # e.g. RDS = http://aws-assets-pricing-prod.s3.amazonaws.com/pricing/rds/mysql/pricing-standard-deployments.js
    @@Compute_Units_Lookup = {}

    private

    # [MB/s capacity, Ops/s capacity]
    PER_SEC_CAPACITIES = {
      'c1.medium' => [118, 5471],
      'c1.xlarge' => [347, 17245],
      'c3.2xlarge' => [947, 63297],
      'c3.4xlarge' => [962, 96546],
      'c3.8xlarge' => [964, 60702],
      'c3.large' => [917, 77972],
      'c3.xlarge' => [932, 60632],
      # c4.2xlarge is EBS-only
      # c4.4xlarge is EBS-only
      # c4.8xlarge is EBS-only
      # c4.large is EBS-only
      # c4.xlarge is EBS-only
      # cache.c1.xlarge is not picked up by CloudWatch
      # cache.m1.large is not picked up by CloudWatch
      # cache.m1.medium is not picked up by CloudWatch
      # cache.m1.small is not picked up by CloudWatch
      # cache.m1.xlarge is not picked up by CloudWatch
      # cache.m2.2xlarge is not picked up by CloudWatch
      # cache.m2.4xlarge is not picked up by CloudWatch
      # cache.m2.xlarge is not picked up by CloudWatch
      # cache.m3.2xlarge is not picked up by CloudWatch
      # cache.m3.large is not picked up by CloudWatch
      # cache.m3.medium is not picked up by CloudWatch
      # cache.m3.xlarge is not picked up by CloudWatch
      # cache.r3.2xlarge is not picked up by CloudWatch
      # cache.r3.4xlarge is not picked up by CloudWatch
      # cache.r3.8xlarge is not picked up by CloudWatch
      # cache.r3.large is not picked up by CloudWatch
      # cache.r3.xlarge is not picked up by CloudWatch
      # cache.t1.micro is not picked up by CloudWatch
      # cache.t2.medium is not picked up by CloudWatch
      # cache.t2.micro is not picked up by CloudWatch
      # cache.t2.small is not picked up by CloudWatch
      # cc1.4xlarge is not picked up by CloudWatch
      'cc2.8xlarge' => [598, 64607],
      # cg1.4xlarge is not picked up by CloudWatch
      'cr1.8xlarge' => [525, 53527],
      'd2.2xlarge' => [928, 119439],
      'd2.4xlarge' => [2136, 266270],
      'd2.8xlarge' => [3367, 225539],
      'd2.xlarge' => [506, 68167],
      # db.cr1.8xlarge, like all RDS instances, are EBS-only
      # db.m1.large, like all RDS instances, are EBS-only
      # db.m1.medium, like all RDS instances, are EBS-only
      # db.m1.small, like all RDS instances, are EBS-only
      # db.m1.xlarge, like all RDS instances, are EBS-only
      # db.m2.2xlarge, like all RDS instances, are EBS-only
      # db.m2.4xlarge, like all RDS instances, are EBS-only
      # db.m2.xlarge, like all RDS instances, are EBS-only
      # db.m3.2xlarge, like all RDS instances, are EBS-only
      # db.m3.large, like all RDS instances, are EBS-only
      # db.m3.medium, like all RDS instances, are EBS-only
      # db.m3.xlarge, like all RDS instances, are EBS-only
      # db.m4.10xlarge, like all RDS instances, are EBS-only
      # db.m4.2xlarge, like all RDS instances, are EBS-only
      # db.m4.4xlarge, like all RDS instances, are EBS-only
      # db.m4.large, like all RDS instances, are EBS-only
      # db.m4.xlarge, like all RDS instances, are EBS-only
      # db.r3.2xlarge, like all RDS instances, are EBS-only
      # db.r3.4xlarge, like all RDS instances, are EBS-only
      # db.r3.8xlarge, like all RDS instances, are EBS-only
      # db.r3.large, like all RDS instances, are EBS-only
      # db.r3.xlarge, like all RDS instances, are EBS-only
      # db.t1.micro, like all RDS instances, are EBS-only
      # db.t2.large, like all RDS instances, are EBS-only
      # db.t2.medium, like all RDS instances, are EBS-only
      # db.t2.micro, like all RDS instances, are EBS-only
      # db.t2.small, like all RDS instances, are EBS-only
      'g2.2xlarge' => [534, 42731],
      'g2.8xlarge' => [1069, 70756],
      'hi1.4xlarge' => [1824, 50488],
      'hs1.8xlarge' => [2257, 126081],
      'i2.2xlarge' => [949, 89028],
      'i2.4xlarge' => [1890, 172192],
      'i2.8xlarge' => [3618, 313304],
      'i2.xlarge' => [480, 45439],
      'm1.large' => [252, 29830],
      'm1.medium' => [134, 9855],
      'm1.small' => [112, 11776],
      'm1.xlarge' => [436, 34630],
      'm2.2xlarge' => [100, 9455],
      'm2.4xlarge' => [198, 17469],
      'm2.xlarge' => [100, 8855],
      'm3.2xlarge' => [934, 72169],
      'm3.large' => [477, 47711],
      'm3.medium' => [443, 31698],
      'm3.xlarge' => [898, 71540],
      # m4.10xlarge is EBS-only
      # m4.2xlarge is EBS-only
      # m4.4xlarge is EBS-only
      # m4.large is EBS-only
      # m4.xlarge is EBS-only
      'r3.2xlarge' => [238, 34564],
      'r3.4xlarge' => [473, 50525],
      'r3.8xlarge' => [471, 51666],
      'r3.large' => [60, 8812],
      'r3.xlarge' => [119, 17149],
      # t1.micro is EBS-only
      # t2.large is EBS-only
      # t2.medium is EBS-only
      # t2.micro is EBS-only
      # t2.nano is EBS-only
      # t2.small is EBS-only
      'x1.32xlarge' => [15000, 500000],
    }
  end

end
