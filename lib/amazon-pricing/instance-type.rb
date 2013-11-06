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
    attr_accessor :name, :api_name, :memory_in_mb, :disk_in_mb, :platform, :compute_units, :virtual_cores
    
    def initialize(region, api_name, name)
      @category_types = {}

      @region = region
      @name = name
      @api_name = api_name

      @memory_in_mb = @@Memory_Lookup[@api_name]
      @disk_in_mb = @@Disk_Lookup[@api_name]
      @platform = @@Platform_Lookup[@api_name]
      @compute_units = @@Compute_Units_Lookup[@api_name]
      @virtual_cores = @@Virtual_Cores_Lookup[@api_name]
    end

    def category_types
      @category_types.values
    end

    def get_category_type(name)
      @category_types[name]
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def price_per_hour(category_type, type_of_instance, term = nil, isMultiAz = false)
      cat = get_category_type(category_type)
      if isMultiAz
        cat.price_per_hour(type_of_instance, term, isMultiAz) unless cat.nil?
      else
        cat.price_per_hour(type_of_instance, term) unless cat.nil?
      end      
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def prepay(category_type, type_of_instance, term = nil, isMultiAz = false)
      cat = get_category_type(category_type)
      if isMultiAz
        cat.prepay(type_of_instance, term, isMultiAz) unless cat.nil?  
      else
        cat.prepay(type_of_instance, term) unless cat.nil?
      end
      
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

    # Returns [api_name, name]
    def self.get_name(instance_type, size, is_reserved = false)
      lookup = @@Api_Name_Lookup
      lookup = @@Api_Name_Lookup_Reserved if is_reserved

      # Let's handle new instances more gracefully
      unless lookup.has_key? instance_type
        raise UnknownTypeError, "Unknown instance type #{instance_type}", caller
      else
        api_name = lookup[instance_type][size]
      end

      lookup = @@Name_Lookup
      lookup = @@Name_Lookup_Reserved if is_reserved
      name = lookup[instance_type][size]

      [api_name, name]
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

    @@Api_Name_Lookup = {
      'stdODI' => {'sm' => 'm1.small', 'med' => 'm1.medium', 'lg' => 'm1.large', 'xl' => 'm1.xlarge'},
      'hiMemODI' => {'xl' => 'm2.xlarge', 'xxl' => 'm2.2xlarge', 'xxxxl' => 'm2.4xlarge'},
      'hiCPUODI' => {'med' => 'c1.medium', 'xl' => 'c1.xlarge'},
      'hiIoODI' => {'xxxxl' => 'hi1.4xlarge'},
      'clusterGPUI' => {'xxxxl' => 'cg1.4xlarge'},
      'clusterComputeI' => {'xxxxl' => 'cc1.4xlarge','xxxxxxxxl' => 'cc2.8xlarge'},
      'uODI' => {'u' => 't1.micro'},
      'secgenstdODI' => {'xl' => 'm3.xlarge', 'xxl' => 'm3.2xlarge'},
      'clusterHiMemODI' => {'xxxxxxxxl' => 'cr1.8xlarge'},
      'hiStoreODI' => {'xxxxxxxxl' => 'hs1.8xlarge'},

      # RDS On-Demand Instances
      'udbInstClass' => {'uDBInst'=>'db.t1.micro'},
      'dbInstClass'=> {'uDBInst' => 'db.t1.micro', 'smDBInst' => 'db.m1.small', 'medDBInst' => 'db.m1.medium', 'lgDBInst' => 'db.m1.large', 'xlDBInst' => 'db.m1.xlarge'},
      'hiMemDBInstClass'=> {'xlDBInst' => 'db.m2.xlarge', 'xxlDBInst' => 'db.m2.2xlarge', 'xxxxDBInst' => 'db.m2.4xlarge'},
      'clusterHiMemDB' => {'xxxxxxxxl' => 'db.m2.8xlarge'},
      'multiAZDBInstClass'=> {'uDBInst' => 'db.t1.micro', 'smDBInst' => 'db.m1.small', 'medDBInst' => 'db.m1.medium', 'lgDBInst' => 'db.m1.large', 'xlDBInst' => 'db.m1.xlarge'},
      'multiAZHiMemInstClass'=> {'xlDBInst' => 'db.m2.xlarge', 'xxlDBInst' => 'db.m2.2xlarge', 'xxxxDBInst' => 'db.m2.4xlarge'},
    }
    @@Name_Lookup = {
      'stdODI' => {'sm' => 'Standard Small', 'med' => 'Standard Medium', 'lg' => 'Standard Large', 'xl' => 'Standard Extra Large'},
      'hiMemODI' => {'xl' => 'Hi-Memory Extra Large', 'xxl' => 'Hi-Memory Double Extra Large', 'xxxxl' => 'Hi-Memory Quadruple Extra Large'},
      'hiCPUODI' => {'med' => 'High-CPU Medium', 'xl' => 'High-CPU Extra Large'},
      'hiIoODI' => {'xxxxl' => 'High I/O Quadruple Extra Large'},
      'clusterGPUI' => {'xxxxl' => 'Cluster GPU Quadruple Extra Large'},
      'clusterComputeI' => {'xxxxl' => 'Cluster Compute Quadruple Extra Large', 'xxxxxxxxl' => 'Cluster Compute Eight Extra Large'},
      'uODI' => {'u' => 'Micro'},
      'secgenstdODI' => {'xl' => 'M3 Extra Large Instance', 'xxl' => 'M3 Double Extra Large Instance'},
      'clusterHiMemODI' => {'xxxxxxxxl' => 'High-Memory Cluster Eight Extra Large'},
      'hiStoreODI' => {'xxxxxxxxl' => 'High-Storage Eight Extra Large'},

      # RDS On-Demand Instances
      'udbInstClass' => {'uDBInst'=>'Standard Micro'},
      'dbInstClass'=> {'uDBInst' => 'Standard Micro', 'smDBInst' => 'Standard Small', 'medDBInst' => 'Standard Medium', 'lgDBInst' => 'Standard Large', 'xlDBInst' => 'Standard Extra Large'},
      'hiMemDBInstClass'=> {'xlDBInst' => 'Standard High-Memory Extra Large', 'xxlDBInst' => 'Standard High-Memory Double Extra Large', 'xxxxDBInst' => 'Standard High-Memory Quadruple Extra Large'},
      'clusterHiMemDB' => {'xxxxxxxxl' => 'Standard High-Memory Cluster Eight Extra Large'},
      'multiAZDBInstClass'=> {'uDBInst' => 'Multi-AZ Micro', 'smDBInst' => 'Multi-AZ Small', 'medDBInst' => 'Multi-AZ Medium', 'lgDBInst' => 'Multi-AZ Large', 'xlDBInst' => 'Multi-AZ Extra Large'},
      'multiAZHiMemInstClass'=> {'xlDBInst' => 'Multi-AZ High-Memory Extra Large', 'xxlDBInst' => 'Multi-AZ High-Memory Double Extra Large', 'xxxxDBInst' => 'Multi-AZ High-Memory Quadruple Extra Large'},
    }
    @@Api_Name_Lookup_Reserved = {
      'stdResI' => {'sm' => 'm1.small', 'med' => 'm1.medium', 'lg' => 'm1.large', 'xl' => 'm1.xlarge'},
      'hiMemResI' => {'xl' => 'm2.xlarge', 'xxl' => 'm2.2xlarge', 'xxxxl' => 'm2.4xlarge'},
      'hiCPUResI' => {'med' => 'c1.medium', 'xl' => 'c1.xlarge'},
      'clusterGPUResI' => {'xxxxl' => 'cg1.4xlarge'},
      'clusterCompResI' => {'xxxxl' => 'cc1.4xlarge', 'xxxxxxxxl' => 'cc2.8xlarge'},
      'uResI' => {'u' => 't1.micro'},
      'hiIoResI' => {'xxxxl' => 'hi1.4xlarge'},
      'secgenstdResI' => {'xl' => 'm3.xlarge', 'xxl' => 'm3.2xlarge'},
      'clusterHiMemResI' => {'xxxxxxxxl' => 'cr1.8xlarge'},
      'hiStoreResI' => {'xxxxxxxxl' => 'hs1.8xlarge'},

      # RDS Reserved Instances
      'stdDeployRes' => {'u' => 'db.t1.micro', 'micro' => 'db.t1.micro', 'sm' => 'db.m1.small', 'med' => 'db.m1.medium', 'lg' => 'db.m1.large', 'xl' => 'db.m1.xlarge', 'xlHiMem' => 'db.m2.xlarge', 'xxlHiMem' => 'db.m2.2xlarge', 'xxxxlHiMem' => 'db.m2.4xlarge', 'xxxxxxxxl' => 'db.m2.8xlarge'},
      'multiAZdeployRes' => {'u' => 'db.t1.micro', 'micro' => 'db.t1.micro', 'sm' => 'db.m1.small', 'med' => 'db.m1.medium', 'lg' => 'db.m1.large', 'xl' => 'db.m1.xlarge', 'xlHiMem' => 'db.m2.xlarge', 'xxlHiMem' => 'db.m2.2xlarge', 'xxxxlHiMem' => 'db.m2.4xlarge', 'xxxxxxxxl' => 'db.m2.8xlarge'},
    }
    @@Name_Lookup_Reserved = {
      'stdResI' => {'sm' => 'Standard Small', 'med' => 'Standard Medium', 'lg' => 'Standard Large', 'xl' => 'Standard Extra Large'},
      'hiMemResI' => {'xl' => 'Hi-Memory Extra Large', 'xxl' => 'Hi-Memory Double Extra Large', 'xxxxl' => 'Hi-Memory Quadruple Extra Large'},
      'hiCPUResI' => {'med' => 'High-CPU Medium', 'xl' => 'High-CPU Extra Large'},
      'clusterGPUResI' => {'xxxxl' => 'Cluster GPU Quadruple Extra Large'},
      'clusterCompResI' => {'xxxxl' => 'Cluster Compute Quadruple Extra Large', 'xxxxxxxxl' => 'Cluster Compute Eight Extra Large'},
      'uResI' => {'u' => 'Micro'},
      'hiIoResI' => {'xxxxl' => 'High I/O Quadruple Extra Large Instance'},
      'secgenstdResI' => {'xl' => 'M3 Extra Large Instance', 'xxl' => 'M3 Double Extra Large Instance'},
      'clusterHiMemResI' => {'xxxxxxxxl' => 'High-Memory Cluster Eight Extra Large'},
      'hiStoreResI' => {'xxxxxxxxl' => 'High-Storage Eight Extra Large'},

      # RDS Reserved Instances
      'stdDeployRes' => {'u' => 'Standard Micro', 'micro' => 'Standard Micro', 'sm' => 'Standard Small', 'med' => 'Standard Medium', 'lg' => 'Standard Large', 'xl' => 'Standard Extra Large', 'xlHiMem' => 'Standard Extra Large High-Memory', 'xxlHiMem' => 'Standard Double Extra Large High-Memory', 'xxxxlHiMem' => 'Standard Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Standard Eight Extra Large'}  ,
      'multiAZdeployRes' => {'u' => 'Multi-AZ Micro', 'micro' => 'Multi-AZ Micro', 'sm' => 'Multi-AZ Small', 'med' => 'Multi-AZ Medium', 'lg' => 'Multi-AZ Large', 'xl' => 'Multi-AZ Extra Large', 'xlHiMem' => 'Multi-AZ Extra Large High-Memory', 'xxlHiMem' => 'Multi-AZ Double Extra Large High-Memory', 'xxxxlHiMem' => 'Multi-AZ Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Multi-AZ Eight Extra Large'},
    }

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
      'db.m1.small' => 1700, 'db.m1.medium' => 3750, 'db.m1.large' => 7500, 'db.m1.xlarge' => 15000,
      'db.m2.xlarge' => 17100, 'db.m2.2xlarge' => 34200, 'db.m2.4xlarge' => 68400, 'db.m2.8xlarge' => 136800
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
      'db.m1.small' => 160, 'db.m1.medium' => 410, 'db.m1.large' =>850, 'db.m1.xlarge' => 1690,
      'db.m2.xlarge' => 420, 'db.m2.2xlarge' => 850, 'db.m2.4xlarge' => 1690, 'db.m2.8xlarge' => 0
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
      'db.m1.small' => 32, 'db.m1.medium' => 32, 'db.m1.large' => 64, 'db.m1.xlarge' => 64,
      'db.m2.xlarge' => 64, 'db.m2.2xlarge' => 64, 'db.m2.4xlarge' => 64, 'db.m2.8xlarge' => 64
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
      'unknown' => 0,
      'db.m1.small' => 1, 'db.m1.medium' => 2, 'db.m1.large' => 4, 'db.m1.xlarge' => 8,
      'db.m2.xlarge' => 6, 'db.m2.2xlarge' => 13, 'db.m2.4xlarge' => 26, 'db.m2.8xlarge' => 52
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
      'unknown' => 0,
      'db.m1.small' => 1, 'db.m1.medium' => 1, 'db.m1.large' => 2, 'db.m1.xlarge' => 4,
      'db.m2.xlarge' => 2, 'db.m2.2xlarge' => 4, 'db.m2.4xlarge' => 8, 'db.m2.8xlarge' => 16
    }
  end

end
