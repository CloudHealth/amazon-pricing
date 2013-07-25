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

    # Initializes and InstanceType object given a region, the internal
    # type (e.g. stdODI) and the json for the specific instance. The json is
    # based on the current undocumented AWS pricing API.
    def initialize(region, api_name, name)
      @operating_systems = {}

      @region = region
      @name = name
      @api_name = api_name

      @memory_in_mb = @@Memory_Lookup[@api_name]
      @disk_in_mb = @@Disk_Lookup[@api_name]
      @platform = @@Platform_Lookup[@api_name]
      @compute_units = @@Compute_Units_Lookup[@api_name]
      @virtual_cores = @@Virtual_Cores_Lookup[@api_name]
    end

    def operating_systems
      @operating_systems.values
    end

    def get_operating_system(name)
      @operating_systems[name]
    end

    # Returns whether an instance_type is available. 
    # operating_system = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def available?(type_of_instance = :ondemand, operating_system = :linux)
      os = get_operating_system(operating_system)
      return false if os.nil?
      os.available?(type_of_instance)
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def price_per_hour(operating_system, type_of_instance, term = nil)
      os = get_operating_system(operating_system)
      os.price_per_hour(type_of_instance, term)
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def prepay(operating_system, type_of_instance, term = nil)
      os = get_operating_system(operating_system)
      os.prepay(type_of_instance, term)
    end

    # operating_system = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def update_pricing(operating_system, type_of_instance, json)
      os = get_operating_system(operating_system)
      if os.nil?
        os = OperatingSystem.new(self, operating_system)
        @operating_systems[operating_system] = os
      end

      if type_of_instance == :ondemand
        # e.g. {"size"=>"sm", "valueColumns"=>[{"name"=>"linux", "prices"=>{"USD"=>"0.060"}}]}
        values = InstanceType::get_values(json)
        price = coerce_price(values[operating_system.to_s])

        os.set_price_per_hour(type_of_instance, nil, price)
      else
        json['valueColumns'].each do |val|
          price = coerce_price(val['prices']['USD'])

          case val["name"]
          when "yrTerm1"
            os.set_prepay(type_of_instance, :year1, price)
          when "yrTerm3"
            os.set_prepay(type_of_instance, :year3, price)
          when "yrTerm1Hourly"
            os.set_price_per_hour(type_of_instance, :year1, price)
          when "yrTerm3Hourly"
            os.set_price_per_hour(type_of_instance, :year3, price)
          end
        end
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def get_breakeven_month(operating_system, type_of_instance, term)
      os = get_operating_system(operating_system)
      os.get_breakeven_month(type_of_instance, term)
    end

    protected

    def coerce_price(price)
      return nil if price.nil? || price == "N/A"
      price.to_f
    end

    #attr_accessor :size, :instance_type

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

    # Turn json into hash table for parsing
    def self.get_values(json)
      # e.g. json = {"size"=>"xl", "valueColumns"=>[{"name"=>"mswinSQL", "prices"=>{"USD"=>"2.427"}}]}
      values = {}
      json['valueColumns'].each do |val|
        values[val['name']] = val['prices']['USD']
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
    }
  end

end
