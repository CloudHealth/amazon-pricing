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
      @disk_in_gb.nil? ? 0 : @disk_in_gb * 1000
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
                @@Compute_Units_Lookup[api_name] = size["ECU"].to_f
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

    def self.get_descriptive_name(api_name)
      @@Name_Lookup[api_name]
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

    @@Name_Lookup = { # basic name and description lookup
      'a1.medium' =>  'General purpose A1 Medium', 'a1.large' =>  'General purpose A1 Large', 'a1.xlarge' =>  'General purpose A1 Extra Large',
      'a1.2xlarge' => 'General purpose A1 Double Extra Large', 'a1.4xlarge' => 'General purpose A1 Quadruple Extra Large',
      'm1.small' => 'Standard Small', 'm1.medium' => 'Standard Medium', 'm1.large' => 'Standard Large', 'm1.xlarge' => 'Standard Extra Large',
      'm2.xlarge' => 'Hi-Memory Extra Large', 'm2.2xlarge' => 'Hi-Memory Double Extra Large', 'm2.4xlarge' => 'Hi-Memory Quadruple Extra Large',
      'm3.medium' => 'M3 Medium Instance', 'm3.large'=>'M3 Large Instance', 'm3.xlarge' => 'M3 Extra Large Instance', 'm3.2xlarge' => 'M3 Double Extra Large Instance',
      'm4.large' => 'M4 Large Instance', 'm4.xlarge' => 'M4 Extra Large Instance', 'm4.2xlarge' => 'M4 Double Extra Large Instance',
      'm4.4xlarge' => 'M4 Quadruple Extra Large Instance', 'm4.10xlarge' => 'M4 Decuple Extra Large Instance',
      'm4.16xlarge' => 'M4 Hextuple Extra Large Instance',
      'm5.large' => 'M5 Large Instance', 'm5.xlarge' => 'M5 Extra Large Instance', 'm5.2xlarge' => 'M5 Double Extra Large Instance',
      'm5.4xlarge' => 'M5 Quadruple Extra Large Instance', 'm5.12xlarge' => 'M5 12XL Instance',
      'm5.24xlarge' => 'M5 24XL Instance',
      'm5d.large' => 'M5d Large Instance', 'm5d.xlarge' => 'M5d Extra Large Instance', 'm5d.2xlarge' => 'M5d Double Extra Large Instance',
      'm5d.4xlarge' => 'M5d Quadruple Extra Large Instance', 'm5d.12xlarge' => 'M5d 12XL Instance',
      'm5d.24xlarge' => 'M5d 24XL Instance',
      'c1.medium' => 'High-CPU Medium', 'c1.xlarge' => 'High-CPU Extra Large',
      'hi1.4xlarge' => 'High I/O Quadruple Extra Large',
      'cg1.4xlarge' => 'Cluster GPU Quadruple Extra Large',
      'cc1.4xlarge' => 'Cluster Compute Quadruple Extra Large', 'cc2.8xlarge' => 'Cluster Compute Eight Extra Large',
      't1.micro' => 'Micro',
      'cr1.8xlarge' => 'High-Memory Cluster Eight Extra Large',
      'hs1.8xlarge' => 'High-Storage Eight Extra Large',
      'g2.2xlarge' => 'Cluster GPU Double Extra Large', 'g2.8xlarge' => 'Cluster GPU Eight Extra Large',
      'g3.4xlarge' => 'Cluster GPU-3 Quadruple Extra Large', 'g3.8xlarge' => 'Cluster GPU-3 Eight Extra Large', 'g3.16xlarge' => 'Cluster GPU-3 Hextuple Extra Large',
      'g3s.xlarge' => 'Cluster GPU-3S Extra Large',
      'p2.xlarge' => 'GPU Compute Extra Large', 'p2.8xlarge' => 'GPU Compute Eight Extra Large', 'p2.16xlarge' => 'GPU Compute Hextuple Extra Large',
      'p3.2xlarge' => 'GPU-3 Compute Double Extra Large', 'p3.8xlarge' => 'GPU-3 Compute Eight Extra Large', 'p3.16xlarge' => 'GPU-3 Compute Hextuple Extra Large',
      'p3dn.24xlarge' => 'GPU-3 Nvidia Twenty Four Extra Large',
      'c3.large' => 'High-Compute Large', 'c3.xlarge' => 'High-Compute Extra Large', 'c3.2xlarge' => 'High-Compute Double Extra Large', 'c3.4xlarge' => 'High-Compute Quadruple Extra Large', 'c3.8xlarge' => 'High-Compute Eight Extra Large',
      'i2.xlarge' => 'High I/O Extra Large', 'i2.2xlarge' => 'High I/O Double Extra Large', 'i2.4xlarge' => 'High I/O Quadruple Extra Large', 'i2.8xlarge' => 'High I/O Eight Extra Large',
      'i3.large' => 'Storage Optimized High I/O Large',
      'i3.xlarge' => 'Storage Optimized High I/O Extra Large', 'i3.2xlarge' => 'Storage Optimized High I/O Double Extra Large',
      'i3.4xlarge' => 'Storage Optimized High I/O Quadruple Extra Large', 'i3.8xlarge' => 'Storage Optimized High I/O Extra Large',
      'i3.16xlarge' => 'Storage Optimized High I/O Hextuple Extra Large',
      'i3.metal' => 'Storage Optimized High I/O Metal',
      'i3p.16xlarge' => 'Storage Optimized VMware High I/O Hextuple Extra Large',
      'd2.xlarge' => 'Dense Storage Extra Large', 'd2.2xlarge' => 'Dense Storage Double Extra Large', 'd2.4xlarge' => 'Dense Storage Quadruple Extra Large', 'd2.8xlarge' => 'Dense Storage Eight Extra Large',
      'h1.2xlarge' => 'Dense Storage H1 Double Extra Large', 'h1.4xlarge' => 'Dense Storage H1 Quadruple Extra Large', 'h1.8xlarge' => 'Dense Storage H1 Eight Extra Large', 'h1.16xlarge' => 'Dense Storage H1 Hextuple Extra Large',
      'r3.large' => 'Memory Optimized Large', 'r3.xlarge' => 'Memory Optimized Extra Large', 'r3.2xlarge' => 'Memory Optimized Double Extra Large', 'r3.4xlarge' => 'Memory Optimized Quadruple Extra Large', 'r3.8xlarge' => 'Memory Optimized Eight Extra Large',
      'r4.large' => 'Memory Optimized Large Enterprise', 'r4.xlarge' => 'Memory Optimized Extra Large Enterprise', 'r4.2xlarge' => 'Memory Optimized Double Extra Large Enterprise', 'r4.4xlarge' => 'Memory Optimized Quadruple Extra Large Enterprise',
        'r4.8xlarge' => 'Memory Optimized Eight Extra Large Enterprise', 'r4.16xlarge' => 'Memory Optimized Hextuple Extra Large Enterprise',
      'r5.large' => 'Memory Optimized Large', 'r5.xlarge' => 'Memory Optimized Extra Large', 'r5.2xlarge' => 'Memory Optimized Double Extra Large', 'r5.4xlarge' => 'Memory Optimized Quadruple Extra Large', 'r5.12xlarge' => 'Memory Optimized Twelve Extra Large',
        'r5.24xlarge' => 'Memory Optimized Twenty Four Extra Large',
      'r5d.large' => 'Memory Optimized Large', 'r5d.xlarge' => 'Memory Optimized Extra Large', 'r5d.2xlarge' => 'Memory Optimized Double Extra Large', 'r5d.4xlarge' => 'Memory Optimized Quadruple Extra Large', 'r5d.12xlarge' => 'Memory Optimized Twelve Extra Large',
        'r5d.24xlarge' => 'Memory Optimized Twenty Four Extra Large',
      't2.nano' => 'Burstable Performance Instance Nano', 't2.micro' => 'Burstable Performance Instance Micro', 't2.small' => 'Burstable Performance Instance Small', 't2.medium' => 'Burstable Performance Instance Medium', 't2.large' => 'Burstable Performance Instance Large',
        't2.xlarge' => 'Burstable Performance Instance Extra Large', 't2.2xlarge' => 'Burstable Performance Instance Double Extra Large',
      't3.nano' => 'Burstable Performance Instance Nano', 't3.micro' => 'Burstable Performance Instance Micro', 't3.small' => 'Burstable Performance Instance Small', 't3.medium' => 'Burstable Performance Instance Medium', 't3.large' => 'Burstable Performance Instance Large',
        't3.xlarge' => 'Burstable Performance Instance Extra Large','t3.2xlarge' => 'Burstable Performance Instance Double Extra Large',
      'c4.large' => 'Compute Optimized Large', 'c4.xlarge' => 'Compute Optimized Extra Large', 'c4.2xlarge' => 'Compute Optimized Double Extra Large', 'c4.4xlarge' => 'Compute Optimized Quadruple Extra Large',
        'c4.8xlarge' => 'Compute Optimized Eight Extra Large',
      'c5.large' => 'Compute Optimized C5 Large', 'c5.xlarge' => 'Compute Optimized C5 Extra Large', 'c5.2xlarge' => 'Compute Optimized C5 Double Extra Large', 'c5.4xlarge' => 'Compute Optimized C5 Quadruple Extra Large',
        'c5.9xlarge' => 'Compute Optimized C5 Nine Extra Large', 'c5.18xlarge' => 'Compute Optimized C5 Eighteen Extra Large',
      'c5d.large' => 'Compute Optimized C5d Large', 'c5d.xlarge' => 'Compute Optimized C5d Extra Large', 'c5d.2xlarge' => 'Compute Optimized C5d Double Extra Large', 'c5d.4xlarge' => 'Compute Optimized C5d Quadruple Extra Large',
        'c5d.9xlarge' => 'Compute Optimized C5d Nine Extra Large', 'c5d.18xlarge' => 'Compute Optimized C5d Eighteen Extra Large',
      'c5n.large' => 'Compute Optimized C5N Large', 'c5n.xlarge' =>  'Compute Optimized C5N Extra Large', 'c5n.2xlarge' => 'Compute Optimized C5N Double Extra Large', 'c5n.4xlarge' => 'Compute Optimized C5N Quadruple Extra Large',
        'c5n.9xlarge' => 'Compute Optimized C5N Nine Extra Large', 'c5n.18xlarge' => 'Compute Optimized C5N Eighteen Extra Large',
      'x1.16xlarge'   => 'Memory Optimized 16 Extra Large Enterprise-class',
        'x1.32xlarge' => 'Memory Optimized 32 Extra Large Enterprise-class',
      'x1e.xlarge'     => 'Memory Optimized Extended Extra Large Enterprise-class',
        'x1e.2xlarge'  => 'Memory Optimized Extended 2 Extra Large Enterprise-class',
        'x1e.4xlarge'  => 'Memory Optimized Extended 4 Extra Large Enterprise-class',
        'x1e.8xlarge'  => 'Memory Optimized Extended 8 Extra Large Enterprise-class',
        'x1e.16xlarge' => 'Memory Optimized Extended 16 Extra Large Enterprise-class',
        'x1e.32xlarge' => 'Memory Optimized Extended 32 Extra Large Enterprise-class',
      'f1.2xlarge' => 'FPGA Hardware Acceleration Double Extra Large', 'f1.4xlarge' => 'FPGA Hardware Acceleration Quadruple Extra Large', 'f1.16xlarge' =>  'FPGA Hardware Acceleration Hextuple Extra Large',
      'z1d.large' => 'Memory Optimized Z1D Large', 'z1d.xlarge' => 'Memory Optimized Z1D Extra large', 'z1d.2xlarge' => 'Memory Optimized Z1D Double Extra Large', 'z1d.3xlarge' => 'Memory Optimized Z1D Triple Extra Large',
        'z1d.6xlarge' => 'Memory Optimized Z1D 6 Extra Large', 'z1d.12xlarge' => 'Memory Optimized Z1D 12 Extra Large',
      'm5a.large' => 'General Purpose M5A Large', 'm5a.xlarge' => 'General Purpose M5A Extra Large', 'm5a.2xlarge' => 'General Purpose M5A Double Extra Large', 'm5a.4xlarge' => 'General Purpose M5A Quadruple Extra Large',
        'm5a.12xlarge' => 'General Purpose M5A Twelve Extra Large',  'm5a.24xlarge' => 'General Purpose M5A Twenty Four Extra Large',
      'r5a.large' => 'Memory Optimized R5A Large', 'r5a.xlarge' => 'Memory Optimized R5A Extra Large', 'r5a.2xlarge' => 'Memory Optimized R5A Double Extra Large', 'r5a.4xlarge' => 'Memory Optimized R5A Quadruple Extra Large',
        'r5a.12xlarge' => 'Memory Optimized R5A Twelve Extra Large', 'r5a.24xlarge' => 'Memory Optimized R5A Twenty Four Extra Large',
      'u-6tb1.metal' => "Memory Optimized u-6tb1 Metal",
      'u-9tb1.metal' => "Memory Optimized u-9tb1 Metal",
      'u-12tb1.metal' => "Memory Optimized u-12tb1 Metal",
    }
    @@Disk_Lookup = { # size of disk supported (local disk size) TOTAL size in gb
      'a1.medium' => 0, 'a1.large' => 0, 'a1.xlarge' => 0,  'a1.2xlarge' => 0, 'a1.4xlarge' => 0, # ebs-optimized
      'm1.small' => 160, 'm1.medium' => 410, 'm1.large' =>850, 'm1.xlarge' => 1690,
      'm2.xlarge' => 420, 'm2.2xlarge' => 850, 'm2.4xlarge' => 1690,
      'm3.medium' => 4, 'm3.large' => 32, 'm3.xlarge' => 80, 'm3.2xlarge' => 160,
      'm4.large' => 0, 'm4.xlarge' => 0, 'm4.2xlarge' => 0, 'm4.4xlarge' => 0, 'm4.10xlarge' => 0, 'm4.16xlarge' => 0,
      'm5.large' => 0, 'm5.xlarge' => 0, 'm5.2xlarge' => 0, 'm5.4xlarge' => 0, 'm5.12xlarge' => 0, 'm5.24xlarge' => 0,
      'm5d.large' => 0, 'm5d.xlarge' => 0, 'm5d.2xlarge' => 0, 'm5d.4xlarge' => 0, 'm5d.12xlarge' => 0, 'm5d.24xlarge' => 0,
      'c1.medium' => 350, 'c1.xlarge' => 1690,
      'hi1.4xlarge' => 2048,
      'cg1.4xlarge' => 1690,
      'cc1.4xlarge' => 1690, 'cc2.8xlarge' => 3370,
      't1.micro' => 160,
      'cr1.8xlarge' => 240,
      'hs1.8xlarge' => 48000,
      'g2.2xlarge' => 60, 'g2.8xlarge' => 240,
      'g3.4xlarge' => 0, 'g3.8xlarge' => 0, 'g3.16xlarge' => 0, # g3 are ebs-only
      'g3s.xlarge' => 0, # g3s are ebs-only
      'db.m1.small' => 160, 'db.m1.medium' => 410, 'db.m1.large' =>850, 'db.m1.xlarge' => 1690,
      'db.m2.xlarge' => 420, 'db.m2.2xlarge' => 850, 'db.m2.4xlarge' => 1690, 'db.cr1.8xlarge' => 1690,
      'db.t1.micro' => 160,
      'c3.large' => 32, 'c3.xlarge' => 80, 'c3.2xlarge' => 160, 'c3.4xlarge' => 320, 'c3.8xlarge' => 640,
      'i2.xlarge' => 800, 'i2.2xlarge' => 1600, 'i2.4xlarge' => 3200, 'i2.8xlarge' => 6400,
      'i3.large' => 475, 'i3.xlarge' => 950, 'i3.2xlarge' => 1900, 'i3.4xlarge' => 3800, 'i3.8xlarge' => 7600, 'i3.16xlarge' => 15200, 'i3.metal' => 15200, 'i3p.16xlarge' => 15200,
      'd2.xlarge' => 6000, 'd2.2xlarge' => 12000, 'd2.4xlarge' => 24000, 'd2.8xlarge' => 48000,
      'h1.2xlarge' => 2000, 'h1.4xlarge' => 4000, 'h1.8xlarge' => 8000, 'h1.16xlarge' => 16000,
      'r3.large' => 32, 'r3.xlarge' => 80, 'r3.2xlarge' => 160, 'r3.4xlarge' => 320, 'r3.8xlarge' => 640,
      'r4.large' => 0, 'r4.xlarge' => 0, 'r4.2xlarge' => 0, 'r4.4xlarge' => 0, 'r4.8xlarge' => 0, 'r4.16xlarge' => 0,
      'r5.large' => 0, 'r5.xlarge' => 0, 'r5.2xlarge' => 0, 'r5.4xlarge' => 0, 'r5.12xlarge' => 0, 'r5.24xlarge' => 0, # ebs-optimized
      'r5d.large' => 75, 'r5d.xlarge' => 150, 'r5d.2xlarge' => 300, 'r5d.4xlarge' => 600, 'r5d.12xlarge' => 1800, 'r5d.24xlarge' => 3600, #NVMe
      't2.nano' => 0, 't2.micro' => 0, 't2.small' => 0, 't2.medium' => 0, 't2.large' => 0, 't2.xlarge' => 0, 't2.2xlarge' => 0,
      't3.nano' => 0, 't3.micro' => 0, 't3.small' => 0, 't3.medium' => 0, 't3.large' => 0, 't3.xlarge' => 0, 't3.2xlarge' => 0, #ebs-only
      'c4.large' => 0, 'c4.xlarge' => 0, 'c4.2xlarge' => 0, 'c4.4xlarge' => 0, 'c4.8xlarge' => 0,
      'c5.large' => 0, 'c5.xlarge' => 0, 'c5.2xlarge' => 0, 'c5.4xlarge' => 0, 'c5.9xlarge' => 0, 'c5.18xlarge' => 0, # ebs-optimized
      'c5n.large' =>  0,'c5n.xlarge' =>  0,'c5n.2xlarge' => 0, 'c5n.4xlarge' => 0,  'c5n.9xlarge' =>  0, 'c5n.18xlarge' => 0, # ebs-optimized
      'c5d.large' => 50, 'c5d.xlarge' => 100, 'c5d.2xlarge' => 225, 'c5d.4xlarge' => 450, 'c5d.9xlarge' => 900, 'c5d.18xlarge' => 1800, # NVMe
      'x1.16xlarge' => 1920, 'x1.32xlarge' => 3840,
      'x1e.xlarge' => 120, 'x1e.2xlarge' => 240, 'x1e.4xlarge' => 480, 'x1e.8xlarge' => 960, 'x1e.16xlarge' => 1920, 'x1e.32xlarge' => 3840,
      'p2.xlarge' => 0, 'p2.8xlarge' => 0, 'p2.16xlarge' => 0,  # ebs-optimized
      'p3.2xlarge' => 0, 'p3.8xlarge' => 0, 'p3.16xlarge' => 0, # ebs-optimized
      'p3dn.24xlarge' => 1800,
      'f1.2xlarge' => 470, 'f1.4xlarge' => 940, 'f1.16xlarge' => 3760,
      'z1d.large' => 75, 'z1d.xlarge' => 150, 'z1d.2xlarge' => 300, 'z1d.3xlarge' => 450, 'z1d.6xlarge' => 900, 'z1d.12xlarge' => 1800, # NVMe
      'm5a.large' => 0, 'm5a.xlarge' => 0, 'm5a.2xlarge' => 0, 'm5a.4xlarge' => 0, 'm5a.12xlarge' => 0, 'm5a.24xlarge' => 0, #ebs-only
      'r5a.large' => 0, 'r5a.xlarge' => 0, 'r5a.2xlarge' => 0, 'r5a.4xlarge' => 0, 'r5a.12xlarge' => 0, 'r5a.24xlarge' => 0, #ebs-only
      'u-6tb1.metal' =>  0, #ebs-only
      'u-9tb1.metal' =>  0, #ebs-only
      'u-12tb1.metal' => 0, #ebs-only
    }
    @@Platform_Lookup = { #bit width of cpu
      'a1.medium' =>  64, 'a1.large' =>  64,   'a1.xlarge' =>  64, 'a1.2xlarge' => 64, 'a1.4xlarge' => 64,
      'm1.small' => 32, 'm1.medium' => 32, 'm1.large' => 64, 'm1.xlarge' => 64,
      'm2.xlarge' => 64, 'm2.2xlarge' => 64, 'm2.4xlarge' => 64,
      'm3.medium' => 64, 'm3.large' => 64, 'm3.xlarge' => 64, 'm3.2xlarge' => 64,
      'm4.large' => 64, 'm4.xlarge' => 64, 'm4.2xlarge' => 64, 'm4.4xlarge' => 64, 'm4.10xlarge' => 64, 'm4.16xlarge' => 64,
      'm5.large' => 64, 'm5.xlarge' => 64, 'm5.2xlarge' => 64, 'm5.4xlarge' => 64, 'm5.12xlarge' => 64, 'm5.24xlarge' => 64,
      'm5d.large' => 64, 'm5d.xlarge' => 64, 'm5d.2xlarge' => 64, 'm5d.4xlarge' => 64, 'm5d.12xlarge' => 64, 'm5d.24xlarge' => 64,
      'c1.medium' => 32, 'c1.xlarge' => 64,
      'hi1.4xlarge' => 64,
      'cg1.4xlarge' => 64,
      'cc1.4xlarge' => 64, 'cc2.8xlarge' => 64,
      't1.micro' => 32,
      'cr1.8xlarge' => 64,
      'hs1.8xlarge' => 64,
      'g2.2xlarge' => 64, 'g2.8xlarge' => 64,
      'g3.4xlarge' => 64, 'g3.8xlarge' => 64, 'g3.16xlarge' => 64,
      'g3s.xlarge' => 64,
      'db.m1.small' => 64, 'db.m1.medium' => 64, 'db.m1.large' => 64, 'db.m1.xlarge' => 64,
      'db.m2.xlarge' => 64, 'db.m2.2xlarge' => 64, 'db.m2.4xlarge' => 64, 'db.cr1.8xlarge' => 64,
      'db.t1.micro' => 64,
      'c3.large' => 64, 'c3.xlarge' => 64, 'c3.2xlarge' => 64, 'c3.4xlarge' => 64, 'c3.8xlarge' => 64,
      'i2.large' => 64, 'i2.xlarge' => 64, 'i2.2xlarge' => 64, 'i2.4xlarge' => 64, 'i2.8xlarge' => 64,
      'i3.large' => 64, 'i3.xlarge' => 64, 'i3.2xlarge' => 64, 'i3.4xlarge' => 64, 'i3.8xlarge' => 64, 'i3.16xlarge' => 64, 'i3.metal' => 64, 'i3p.16xlarge' => 64,
      'd2.xlarge' => 64, 'd2.2xlarge' => 64, 'd2.4xlarge' => 64, 'd2.8xlarge' => 64,
      'h1.2xlarge' => 64, 'h1.4xlarge' => 64, 'h1.8xlarge' => 64, 'h1.16xlarge' => 64,
      'r3.large' => 64, 'r3.xlarge' => 64, 'r3.2xlarge' => 64, 'r3.4xlarge' => 64, 'r3.8xlarge' => 64,
      'r4.large' => 64, 'r4.xlarge' => 64, 'r4.2xlarge' => 64, 'r4.4xlarge' => 64, 'r4.8xlarge' => 64, 'r4.16xlarge' => 64,
      'r5.large' => 64, 'r5.xlarge' => 64, 'r5.2xlarge' => 64, 'r5.4xlarge' => 64, 'r5.12xlarge' => 64, 'r5.24xlarge' => 64,
      'r5d.large' => 64, 'r5d.xlarge' => 64, 'r5d.2xlarge' => 64, 'r5d.4xlarge' => 64, 'r5d.12xlarge' => 64, 'r5d.24xlarge' => 64,
      't2.nano' => 64, 't2.micro' => 64, 't2.small' => 64, 't2.medium' => 64, 't2.large' => 64, 't2.xlarge' => 64, 't2.2xlarge' => 64,
      't3.nano' => 64, 't3.micro' => 64, 't3.small' => 64, 't3.medium' => 64, 't3.large' => 64, 't3.xlarge' => 64, 't3.2xlarge' => 64,
      'c4.large' => 64, 'c4.xlarge' => 64, 'c4.2xlarge' => 64, 'c4.4xlarge' => 64, 'c4.8xlarge' => 64,
      'c5.large' => 64, 'c5.xlarge' => 64, 'c5.2xlarge' => 64, 'c5.4xlarge' => 64, 'c5.9xlarge' => 64, 'c5.18xlarge' => 64,
      'c5d.large' => 64, 'c5d.xlarge' => 64, 'c5d.2xlarge' => 64, 'c5d.4xlarge' => 64, 'c5d.9xlarge' => 64, 'c5d.18xlarge' => 64,
      'c5n.large' =>  64,  'c5n.xlarge' =>  64, 'c5n.2xlarge' => 64,  'c5n.4xlarge' => 64,  'c5n.9xlarge' =>  64,  'c5n.18xlarge' => 64,
      'x1.16xlarge' => 64, 'x1.32xlarge' => 64,
      'x1e.xlarge' => 64, 'x1e.2xlarge' => 64, 'x1e.4xlarge' => 64, 'x1e.8xlarge' => 64, 'x1e.16xlarge' => 64, 'x1e.32xlarge' => 64,
      'p2.xlarge' => 64, 'p2.8xlarge' => 64, 'p2.16xlarge' => 64,
      'p3.2xlarge' => 64, 'p3.8xlarge' => 64, 'p3.16xlarge' => 64,
      'p3dn.24xlarge' => 64,
      'z1d.large' => 64, 'z1d.xlarge' => 64, 'z1d.2xlarge' => 64, 'z1d.3xlarge' => 64, 'z1d.6xlarge' => 64, 'z1d.12xlarge' => 64,
      'm5a.large' => 64, 'm5a.xlarge' => 64, 'm5a.2xlarge' => 64, 'm5a.4xlarge' => 64, 'm5a.12xlarge' => 64, 'm5a.24xlarge' => 64,
      'r5a.large' => 64, 'r5a.xlarge' => 64, 'r5a.2xlarge' => 64, 'r5a.4xlarge' => 64, 'r5a.12xlarge' => 64, 'r5a.24xlarge' => 64,
      'u-6tb1.metal' =>  64,
      'u-9tb1.metal' =>  64,
      'u-12tb1.metal' => 64,
    }
    @@Disk_Type_Lookup = { #type of local storage for the disk
      'a1.medium' => :ebs,'a1.large' =>  :ebs, 'a1.xlarge' => :ebs, 'a1.2xlarge' => :ebs, 'a1.4xlarge' => :ebs,
      'm1.small' => :ephemeral, 'm1.medium' => :ephemeral, 'm1.large' => :ephemeral, 'm1.xlarge' => :ephemeral,
      'm2.xlarge' => :ephemeral, 'm2.2xlarge' => :ephemeral, 'm2.4xlarge' => :ephemeral,
      'm3.medium' => :ssd, 'm3.large' => :ssd, 'm3.xlarge' => :ssd, 'm3.2xlarge' => :ssd,
      'm4.large' => :ebs, 'm4.xlarge' => :ebs, 'm4.2xlarge' => :ebs, 'm4.4xlarge' => :ebs, 'm4.10xlarge' => :ebs, 'm4.16xlarge' => :ebs,
      'm5.large' => :ebs, 'm5.xlarge' => :ebs, 'm5.2xlarge' => :ebs, 'm5.4xlarge' => :ebs, 'm5.12xlarge' => :ebs, 'm5.24xlarge' => :ebs,
      'm5d.large' => :ssd, 'm5d.xlarge' => :ssd, 'm5d.2xlarge' => :ssd, 'm5d.4xlarge' => :ssd, 'm5d.12xlarge' => :ssd, 'm5d.24xlarge' => :ssd,
      'c1.medium' => :ephemeral, 'c1.xlarge' => :ephemeral,
      'hi1.4xlarge' => :ssd,
      'cg1.4xlarge' => :ephemeral,
      'cc1.4xlarge' => :ephemeral, 'cc2.8xlarge' => :ephemeral,
      't1.micro' => :ebs,
      'cr1.8xlarge' => :ssd,
      'hs1.8xlarge' => :ephemeral,
      'g2.2xlarge' => :ssd, 'g2.8xlarge' => :ssd,
      'g3.4xlarge' => :ebs, 'g3.8xlarge' => :ebs, 'g3.16xlarge' => :ebs,
      'g3s.xlarge' => :ebs,
      'unknown' => :ephemeral,
      'db.m1.small' => :ephemeral, 'db.m1.medium' => :ephemeral, 'db.m1.large' => :ephemeral, 'db.m1.xlarge' => :ephemeral,
      'db.m2.xlarge' => :ephemeral, 'db.m2.2xlarge' => :ephemeral, 'db.m2.4xlarge' => :ephemeral, 'db.cr1.8xlarge' => :ephemeral,
      'db.t1.micro' => :ebs,
      'c3.large' => :ssd, 'c3.xlarge' => :ssd, 'c3.2xlarge' => :ssd, 'c3.4xlarge' => :ssd, 'c3.8xlarge' => :ssd,
      'i2.large' => :ssd, 'i2.xlarge' => :ssd, 'i2.2xlarge' => :ssd, 'i2.4xlarge' => :ssd, 'i2.8xlarge' => :ssd,
      'i3.large' => :ssd, 'i3.xlarge' => :ssd, 'i3.2xlarge' => :ssd, 'i3.4xlarge' => :ssd, 'i3.8xlarge' => :ssd, 'i3.16xlarge' => :ssd, 'i3.metal' => :ssd, 'i3p.16xlarge' => :ssd,
      'd2.xlarge' => :ephemeral, 'd2.2xlarge' => :ephemeral, 'd2.4xlarge' => :ephemeral, 'd2.8xlarge' => :ephemeral,
      'h1.2xlarge' => :ephemeral, 'h1.4xlarge' => :ephemeral, 'h1.8xlarge' => :ephemeral, 'h1.16xlarge' => :ephemeral,
      'r3.large' => :ssd, 'r3.xlarge' => :ssd, 'r3.2xlarge' => :ssd, 'r3.4xlarge' => :ssd, 'r3.8xlarge' => :ssd,
      'r4.large' => :ebs, 'r4.xlarge' => :ebs, 'r4.2xlarge' => :ebs, 'r4.4xlarge' => :ebs, 'r4.8xlarge' => :ebs, 'r4.16xlarge' => :ebs,
      'r5.large' => :ebs, 'r5.xlarge' => :ebs, 'r5.2xlarge' => :ebs, 'r5.4xlarge' => :ebs, 'r5.12xlarge' => :ebs, 'r5.24xlarge' => :ebs,
      'r5d.large' => :ssd, 'r5d.xlarge' => :ssd, 'r5d.2xlarge' => :ssd, 'r5d.4xlarge' => :ssd, 'r5d.12xlarge' => :ssd, 'r5d.24xlarge' => :ssd,
      't2.nano' => :ebs, 't2.micro' => :ebs, 't2.small' => :ebs, 't2.medium' => :ebs, 't2.large' => :ebs, 't2.xlarge' => :ebs, 't2.2xlarge' => :ebs,
      't3.nano' => :ebs, 't3.micro' => :ebs, 't3.small' => :ebs, 't3.medium' => :ebs, 't3.large' => :ebs, 't3.xlarge' => :ebs, 't3.2xlarge' => :ebs,
      'c4.large' => :ebs, 'c4.xlarge' => :ebs, 'c4.2xlarge' => :ebs, 'c4.4xlarge' => :ebs, 'c4.8xlarge' => :ebs,
      'c5.large' => :ebs, 'c5.xlarge' => :ebs, 'c5.2xlarge' => :ebs, 'c5.4xlarge' => :ebs, 'c5.9xlarge' => :ebs, 'c5.18xlarge' => :ebs,
      'c5n.large' =>  :ebs, 'c5n.xlarge' =>  :ebs, 'c5n.2xlarge' => :ebs, 'c5n.4xlarge' => :ebs, 'c5n.9xlarge' => :ebs, 'c5n.18xlarge' => :ebs,
      'c5d.large' => :ssd, 'c5d.xlarge' => :ssd, 'c5d.2xlarge' => :ssd, 'c5d.4xlarge' => :ssd, 'c5d.9xlarge' => :ssd, 'c5d.18xlarge' => :ssd,
      'x1.16xlarge' => :ssd, 'x1.32xlarge' => :ssd,
      'x1e.xlarge' => :ssd, 'x1e.2xlarge' => :ssd, 'x1e.4xlarge' => :ssd, 'x1e.8xlarge' => :ssd, 'x1e.16xlarge' => :ssd, 'x1e.32xlarge' => :ssd,
      'p2.xlarge' => :ebs, 'p2.8xlarge' => :ebs, 'p2.16xlarge' => :ebs,
      'p3.2xlarge' => :ebs, 'p3.8xlarge' => :ebs, 'p3.16xlarge' => :ebs,
      'p3dn.24xlarge' => :ssd,
      'f1.2xlarge' => :ssd, 'f1.4xlarge' => :ssd,'f1.16xlarge' => :ssd,
      'z1d.large' => :ssd, 'z1d.xlarge' => :ssd, 'z1d.2xlarge' => :ssd, 'z1d.3xlarge' => :ssd, 'z1d.6xlarge' => :ssd, 'z1d.12xlarge' => :ssd,
      'm5a.large' => :ebs, 'm5a.xlarge' => :ebs, 'm5a.2xlarge' => :ebs, 'm5a.4xlarge' => :ebs, 'm5a.12xlarge' => :ebs, 'm5a.24xlarge' => :ebs,
      'r5a.large' => :ebs, 'r5a.xlarge' => :ebs, 'r5a.2xlarge' => :ebs, 'r5a.4xlarge' => :ebs, 'r5a.12xlarge' => :ebs, 'r5a.24xlarge' => :ebs,
      'u-6tb1.metal' =>  :ebs,
      'u-9tb1.metal' =>  :ebs,
      'u-12tb1.metal' => :ebs,
    }

    # NOTE: These are populated by "populate_lookups"
    #       But... AWS does not always provide memory info (e.g. t2, r3, cache.*), so those are hardcoded below
    @@Memory_Lookup = { # these are provided via the pricing json
      'cache.r3.large' => 13500, 'cache.r3.xlarge' => 28400, 'cache.r3.2xlarge' => 58200, 'cache.r3.4xlarge' => 118000, 'cache.r3.8xlarge' => 237000,
      'r3.large' => 15250, 'r3.xlarge' => 30500, 'r3.2xlarge' => 61000, 'r3.4xlarge' => 122000, 'r3.8xlarge' => 244000,
      'r4.large' => 15250, 'r4.xlarge' => 30500, 'r4.2xlarge' => 61000, 'r4.4xlarge' => 122000, 'r4.8xlarge' => 244000, 'r4.16xlarge' => 488000,
      'cache.m3.medium' => 2780, 'cache.m3.large' => 6050, 'cache.m3.xlarge' => 13300, 'cache.m3.2xlarge' => 27900,
      't2.nano' => 500, 't2.micro' => 1000, 't2.small' => 2000, 't2.medium' => 4000, 't2.large' => 8000, 't2.xlarge' => 16000, 't2.2xlarge' => 32000,
      't3.nano' => 500, 't3.micro' => 1000, 't3.small' => 2000, 't3.medium' => 4000, 't3.large' => 8000, 't3.xlarge' => 16000, 't3.2xlarge' => 32000,
      'cache.t2.micro' => 555, 'cache.t2.small' =>  1550, 'cache.t2.medium' => 3220,
      'cache.m1.small' => 1300, 'cache.m1.medium' => 3350, 'cache.m1.large' => 7100, 'cache.m1.xlarge' => 14600,
      'cache.m2.xlarge' => 16700, 'cache.m2.2xlarge' => 33800, 'cache.m2.4xlarge' => 68000,
      'cache.c1.xlarge' => 6600,
      'cache.t1.micro' => 213,
      'cache.r4.large' => 12300, 'cache.r4.xlarge' => 25050, 'cache.r4.2xlarge' => 50470, 'cache.r4.4xlarge' => 101380,
         'cache.r4.8xlarge' => 203260, 'cache.r4.16xlarge' => 407000,
    }
    @@Virtual_Cores_Lookup = {
      'r3.large' => 2, 'r3.xlarge' => 4, 'r3.2xlarge' => 8, 'r3.4xlarge' => 16, 'r3.8xlarge' => 32,
      'r4.large' => 2, 'r4.xlarge' => 4, 'r4.2xlarge' => 8, 'r4.4xlarge' => 16, 'r4.8xlarge' => 32, 'r4.16xlarge' => 64,
      'r5.large' => 2, 'r5.xlarge' => 4, 'r5.2xlarge' => 8, 'r5.4xlarge' => 16, 'r5.12xlarge' => 48, 'r5.24xlarge' => 96,
      't2.nano' => 1, 't2.micro' => 1, 't2.small' => 1, 't2.medium' => 2, 't2.large' => 2, 't2.xlarge' => 4, 't2.2xlarge' => 8,
      't3.nano' => 2, 't3.micro' => 2, 't3.small' => 2, 't3.medium' => 2, 't3.large' => 2, 't3.xlarge' => 4, 't3.2xlarge' => 8,
      'm5a.large' => 2, 'm5a.xlarge' => 4, 'm5a.2xlarge' => 8, 'm5a.4xlarge' => 16, 'm5a.12xlarge' => 48, 'm5a.24xlarge' => 96,
      'r5a.large' => 2, 'r5a.xlarge' => 4, 'r5a.2xlarge' => 8, 'r5a.4xlarge' => 16, 'r5a.12xlarge' => 48, 'r5a.24xlarge' => 96,
    }

    # Due to fact AWS pricing API only reports these for EC2, we will fetch from EC2 and keep around for lookup
    # e.g. EC2 = http://aws-assets-pricing-prod.s3.amazonaws.com/pricing/ec2/linux-od.js
    # e.g. RDS = http://aws-assets-pricing-prod.s3.amazonaws.com/pricing/rds/mysql/pricing-standard-deployments.js
    @@Compute_Units_Lookup = {}

    private

    # [MB/s capacity, Ops/s capacity]
    # EBSoptimized published capacities:
    #  - cf: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSOptimized.html
    #  - MB/s (128KB I/O size), IOPS (16KB IO size)
    PER_SEC_CAPACITIES = {
      'a1.medium' => [437, 20000],
      'a1.large' => [437, 20000],
      'a1.xlarge' => [437, 20000],
      'a1.2xlarge' =>[437, 20000],
      'a1.4xlarge' =>[437, 20000],
      'c1.medium' => [118, 5471],
      'c1.xlarge' => [125, 8000],   # EBS
      'c3.xlarge'  => [ 62,  4000], # EBSOptimized
      'c3.2xlarge' => [125,  8000], # EBSOptimized
      'c3.4xlarge' => [250, 16000], # EBSOptimized
      # 'c3.8xlarge' # does NOT have dedicated EBSOptimized
      'c4.large'   => [ 62,  4000], # EBSOptimized
      'c4.xlarge'  => [ 94,  6000], # EBSOptimized
      'c4.2xlarge' => [125,  8000], # EBSOptimized
      'c4.4xlarge' => [250, 16000], # EBSOptimized
      'c4.8xlarge' => [500, 32000], # EBSOptimized
      'c5.large'    => [ 281, 16000], # EBSOptimized  peak.30min/24hrs, else [ 66, 4000]
      'c5.xlarge'   => [ 281, 16000], # EBSOptimized  peak.30min/24hrs, else [100, 6000]
      'c5.2xlarge'  => [ 281, 16000], # EBSOptimized  peak.30min/24hrs, else [141, 8000]
      'c5.4xlarge'  => [ 281, 16000], # EBSOptimized
      'c5.9xlarge'  => [ 563, 32000], # EBSOptimized
      'c5.18xlarge' => [1125, 64000], # EBSOptimized
      'c5d.large'    => [437, 20000], # NVMe
      'c5d.xlarge'   => [437, 20000], # NVMe
      'c5d.2xlarge'  => [437, 20000], # NVMe
      'c5d.4xlarge'  => [437, 20000], # NVMe
      'c5d.9xlarge'  => [875, 40000], # NVMe
      'c5d.18xlarge' => [1750, 80000], # NVMe
      'c5n.large' => [437, 20000],
      'c5n.xlarge' => [437, 20000],
      'c5n.2xlarge' => [437, 20000],
      'c5n.4xlarge' => [437, 20000],
      'c5n.9xlarge' => [75, 40000],
      'c5n.18xlarge' => [1750, 80000],
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
      'd2.xlarge'  => [ 94,  6000], # EBSOptimized
      'd2.2xlarge' => [125,  8000], # EBSOptimized
      'd2.4xlarge' => [250, 16000], # EBSOptimized
      'd2.8xlarge' => [500, 32000], # EBSOptimized
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
      'f1.2xlarge' => [ 212, 12000], # EBSOptimized
      'f1.4xlarge' => [ 400, 44000], # EBSOptimized
      'f1.16xlarge'=> [1750, 75000], # EBSOptimized
      'g2.2xlarge' => [125, 8000], # EBSOptimized
      'g3.4xlarge' => [ 437, 20000], # EBSOptimized
      'g3,8xlarge' => [ 875, 40000], # EBSOptimized
      'g3.16xlarge'=> [1750, 80000], # EBSOptimized
      'g3s.xlarge' => [100, 5000], # EBSOptimized
      'h1.2xlarge'  => [ 218, 12000], # EBSOptimized
      'h1.4xlarge'  => [ 437, 20000], # EBSOptimized
      'h1.8xlarge'  => [ 875, 40000], # EBSOptimized
      'h1.16xlarge' => [1750, 80000], # EBSOptimized
      'hi1.4xlarge' => [1824, 50488],
      'hs1.8xlarge' => [2257, 126081],
      'i2.xlarge'  => [ 62,  4000], # EBSOptimized
      'i2.2xlarge' => [125,  8000], # EBSOptimized
      'i2.4xlarge' => [250, 16000], # EBSOptimized
      # 'i2.8xlarge' # does NOT have dedicated EBSOptimized
      'i3.large'    => [  53,  3000], # EBSOptimized
      'i3.xlarge'   => [ 106,  6000], # EBSOptimized
      'i3.2xlarge'  => [ 212, 12000], # EBSOptimized
      'i3.4xlarge'  => [ 437, 16000], # EBSOptimized
      'i3.8xlarge'  => [ 875, 32500], # EBSOptimized
      'i3.16xlarge' => [1750, 65000], # EBSOptimized
      'i3.metal'    => [1250, 64000], # EBSOptimized
      'i3p.16xlarge' => [1250, 64000], # EBSOptimized
      'm1.large'  => [ 62, 4000], # EBSOptimized
      'm1.xlarge' => [125, 8000], # EBSOptimized
      'm2.2xlarge' => [ 62, 4000], # EBSOptimized
      'm2.4xlarge' => [125, 8000], # EBSOptimized
      'm3.xlarge'  => [ 62, 4000], # EBSOptimized
      'm3.2xlarge' => [125, 8000], # EBSOptimized
      'm4.large'   => [  56,  3600], # EBSOptimized
      'm4.xlarge'  => [  94,  6000], # EBSOptimized
      'm4.2xlarge' => [ 125,  8000], # EBSOptimized
      'm4.4xlarge' => [ 250, 16000], # EBSOptimized
      'm4.10xlarge'=> [ 500, 32000], # EBSOptimized
      'm4.16xlarge'=> [1250, 65000], # EBSOptimized
      'm5.large'   => [ 265, 16000], # EBSOptimized  peak.30min/24hrs, else [ 60, 3600]
      'm5.xlarge'  => [ 265, 16000], # EBSOptimized  peak.30min/24hrs, else [100, 6000]
      'm5.2xlarge' => [ 265, 16000], # EBSOptimized  peak.30min/24hrs, else [146, 8333]
      'm5.4xlarge' => [ 265, 16000], # EBSOptimized
      'm5.12xlarge'=> [ 625, 32500], # EBSOptimized
      'm5.24xlarge'=> [1250, 65000], # EBSOptimized
      'm5d.large'   => [ 2120, 16000], # NVMe
      'm5d.xlarge'  => [ 2120, 16000], # NVMe
      'm5d.2xlarge' => [ 2120, 16000], # NVMe
      'm5d.4xlarge' => [ 2210, 16000], # NVMe
      'm5d.12xlarge'=> [ 5000, 32000], # NVMe
      'm5d.24xlarge'=> [10000, 64000], # NVMe
      'p2.xlarge'  => [  94,  6000], # EBSOptimized
      'p2.8xlarge' => [ 625, 32500], # EBSOptimized
      'p2.16xlarge'=> [1250, 65000], # EBSOptimized
      'p3.2xlarge' => [ 218, 10000], # EBSOptimized
      'p3.8xlarge' => [ 875, 40000], # EBSOptimized
      'p3.16xlarge'=> [1750, 80000], # EBSOptimized
      'p3dn.24xlarge' => [1750, 80000], #EBSOptimized
      'r3.xlarge'  => [ 62,  4000],  # EBSOptimized
      'r3.2xlarge' => [125,  8000],  # EBSOptimized
      'r3.4xlarge' => [250, 16000],  # EBSOptimized
      # 'r3.8xlarge' # does NOT have dedicated EBSOptimized
      'r4.large'    => [  53, 3000],  # EBSOptimized
      'r4.xlarge'   => [ 106, 6000],  # EBSOptimized
      'r4.2xlarge'  => [ 212, 12000], # EBSOptimized
      'r4.4xlarge'  => [ 437, 18750], # EBSOptimized
      'r4.8xlarge'  => [ 875, 37500], # EBSOptimized
      'r4.16xlarge' => [1750, 75000], # EBSOptimized
      'r5.large' => [ 437, 18750], # EBSOptimized
      'r5.xlarge' => [ 437, 18750], # EBSOptimized
      'r5.2xlarge' => [ 437, 18750], # EBSOptimized
      'r5.4xlarge' => [ 437, 18750], # EBSOptimized
      'r5.12xlarge' => [ 875, 40000], # EBSOptimized
      'r5.24lxarge' => [ 1750, 80000], # EBSOptimized
      'r5d.large' => [ 437, 18750], # EBSOptimized
      'r5d.xlarge' => [ 437, 18750], # EBSOptimized
      'r5d.2xlarge' => [ 437, 18750], # EBSOptimized
      'r5d.4xlarge' => [ 437, 18750], # EBSOptimized
      'r5d.12xlarge' => [ 875, 40000], # EBSOptimized
      'r5d.24lxarge' => [ 1750, 80000], # EBSOptimized
      # t1.micro is EBS-only
      # t2.large is EBS-only
      # t2.medium is EBS-only
      # t2.micro is EBS-only
      # t2.nano is EBS-only
      # t2.small is EBS-only
      # t2.xlarge is EBS-only
      # t2.2xlarge is EBS-only
      't3.nano' => [ 192, 11800], # EBS Optimized
      't3.micro' => [ 192, 11800], # EBS Optimized
      't3.small' => [ 192, 11800], # EBS Optimized
      't3.medium' => [ 192, 11800], # EBS Optimized
      't3.large' => [ 256, 15700], # EBS Optimized
      't3.xlarge' => [256, 15700], # EBS Optimized
      't3.2xlarge' => [ 256, 15700], # EBS Optimized
      'x1.16xlarge' => [ 875, 40000],  # EBSOptimized
      'x1.32xlarge' => [1750, 80000],  # EBSOptimized
      'x1e.xlarge'   => [  62, 3700],  # EBSOptimized
      'x1e.2xlarge'  => [ 125, 7400],  # EBSOptimized
      'x1e.4xlarge'  => [ 219, 10000], # EBSOptimized
      'x1e.8xlarge'  => [ 437, 20000], # EBSOptimized
      'x1e.16xlarge' => [ 875, 40000], # EBSOptimized
      'x1e.32xlarge' => [1750, 80000], # EBSOptimized
      'z1d.large' => [ 291, 13333], # EBSOptimized
      'z1d.xlarge' => [ 291, 13333], # EBSOptimized
      'z1d.2xlarge' => [ 292, 13333], # EBSOptimized
      'z1d.3xlarge' => [ 438, 20000], # EBSOptimized
      'z1d.6xlarge' => [ 875, 40000], # EBSOptimized
      'z1d.12xlarge' => [ 1750, 80000], # EBSOptimized
      'm5a.large' => [ 265, 16000 ], #EBSOptimized
      'm5a.xlarge' => [ 265, 16000 ], #EBSOptimized
      'm5a.2xlarge' => [ 265, 16000 ], #EBSOptimized
      'm5a.4xlarge' => [ 265, 16000 ], #EBSOptimized
      'm5a.12xlarge' => [ 675, 30000 ], #EBSOptimized
      'm5a.24xlarge' => [ 1250, 60000 ], #EBSOptimized
      'r5a.large' => [ 265, 16000 ], #EBSOptimized
      'r5a.xlarge' => [ 265, 16000 ], #EBSOptimized
      'r5a.2xlarge' => [ 265, 16000 ], #EBSOptimized
      'r5a.4xlarge' => [ 265, 16000 ], #EBSOptimized
      'r5a.12xlarge' => [ 625, 30000 ], #EBSOptimized
      'r5a.24xlarge' => [ 1250, 60000 ], #EBSOptimized
      'u-6tb1.metal' => [ 1750, 80000], #EBSOptimized
      'u-9tb1.metal' =>  [ 1750, 80000], #EBSOptimized
      'u-12tb1.metal' => [ 1750, 80000], #EBSOptimized
    }
  end
end