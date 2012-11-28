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
    attr_accessor :name, :api_name, :linux_price_per_hour, :windows_price_per_hour,
      :memory_in_mb, :disk_in_mb, :platform, :compute_units, :virtual_cores

    # Initializes and InstanceType object given a region, the internal
    # type (e.g. stdODI) and the json for the specific instance. The json is
    # based on the current undocumented AWS pricing API.
    def initialize(region, instance_type, json)
      values = InstanceType::get_values(json)

      @size = json['size']
      @linux_price_per_hour = values['linux'].to_f
      @linux_price_per_hour = nil if @linux_price_per_hour == 0
      @windows_price_per_hour = values['mswin'].to_f
      @windows_price_per_hour = nil if @windows_price_per_hour == 0
      @instance_type = instance_type

      @api_name = self.class.get_api_name(@instance_type, @size)
      @name = self.class.get_name(@instance_type, @size)

      @memory_in_mb = @@Memory_Lookup[@api_name]
      @disk_in_mb = @@Disk_Lookup[@api_name]
      @platform = @@Platform_Lookup[@api_name]
      @compute_units = @@Compute_Units_Lookup[@api_name]
      @virtual_cores = @@Virtual_Cores_Lookup[@api_name]
    end

    # Returns whether an instance_type is available. 
    # Optionally can specify the specific platform (:linix or :windows).
    def available?(platform = nil)
      return @linux_price_per_hour != nil if platform == :linux
      return @windows_price_per_hour != nil if platform == :windows
      return @linux_price_per_hour != nil || @windows_price_per_hour != nil
    end

    def is_reserved?
      false
    end

    def update(instance_type)
      # Due to new AWS json we have to make two passes through to populate an instance
      @windows_price_per_hour = instance_type.windows_price_per_hour if @windows_price_per_hour.nil?
      @linux_price_per_hour = instance_type.linux_price_per_hour if @linux_price_per_hour.nil?
    end

    protected

    attr_accessor :size, :instance_type

    def self.get_api_name(instance_type, size)
      # Let's handle new instances more gracefully
      unless @@Api_Name_Lookup.has_key? instance_type
        raise UnknownTypeError, "Unknown instance type #{instance_type}", caller
      else
        @@Api_Name_Lookup[instance_type][size]
      end
    end

    def self.get_name(instance_type, size)
      @@Name_Lookup[instance_type][size]
    end

    # Turn json into hash table for parsing
    def self.get_values(json)
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
    }
    @@Memory_Lookup = {
      'm1.small' => 1700, 'm1.medium' => 3750, 'm1.large' => 7500, 'm1.xlarge' => 15000,
      'm2.xlarge' => 17100, 'm2.2xlarge' => 34200, 'm2.4xlarge' => 68400,
      #'m3.xlarge' => 15, 'm3.2xlarge' => 30,
      'c1.medium' => 1700, 'c1.xlarge' => 7000,
      'hi1.4xlarge' => 60500,
      'cg1.4xlarge' => 22000,
      'cc1.4xlarge' => 23000, 'cc2.8xlarge' => 60500,
      't1.micro' => 1700,
      'm3.xlarge' => 15000, 'm3.xlarge' => 30000,
    }
    @@Disk_Lookup = {
      'm1.small' => 160, 'm1.medium' => 410, 'm1.large' =>850, 'm1.xlarge' => 1690,
      'm2.xlarge' => 420, 'm2.2xlarge' => 850, 'm2.4xlarge' => 1690,
      #'m3.xlarge' => 0, 'm3.2xlarge' => 0,
      'c1.medium' => 350, 'c1.xlarge' => 1690,
      'hi1.4xlarge' => 2048,
      'cg1.4xlarge' => 1690,
      'cc1.4xlarge' => 1690, 'cc2.8xlarge' => 3370,
      't1.micro' => 160,
      'm3.xlarge' => 0, 'm3.xlarge' => 0,
    }
    @@Platform_Lookup = {
      'm1.small' => 32, 'm1.medium' => 32, 'm1.large' => 64, 'm1.xlarge' => 64,
      'm2.xlarge' => 64, 'm2.2xlarge' => 64, 'm2.4xlarge' => 64,
      #'m3.xlarge' => 64, 'm3.2xlarge' => 64,
      'c1.medium' => 32, 'c1.xlarge' => 64,
      'hi1.4xlarge' => 64,
      'cg1.4xlarge' => 64,
      'cc1.4xlarge' => 64, 'cc2.8xlarge' => 64,
      't1.micro' => 32,
      'm3.xlarge' => 64, 'm3.xlarge' => 64,
    }
    @@Compute_Units_Lookup = {
      'm1.small' => 1, 'm1.medium' => 2, 'm1.large' => 4, 'm1.xlarge' => 8,
      'm2.xlarge' => 6, 'm2.2xlarge' => 13, 'm2.4xlarge' => 26,
      #'m3.xlarge' => 13, 'm3.2xlarge' => 26,
      'c1.medium' => 5, 'c1.xlarge' => 20,
      'hi1.4xlarge' => 35,
      'cg1.4xlarge' => 34,
      'cc1.4xlarge' => 34, 'cc2.8xlarge' => 88,
      't1.micro' => 2,
      'unknown' => 0,
    }
    @@Virtual_Cores_Lookup = {
      'm1.small' => 1, 'm1.medium' => 1, 'm1.large' => 2, 'm1.xlarge' => 4,
      'm2.xlarge' => 2, 'm2.2xlarge' => 4, 'm2.4xlarge' => 8,
      #'m3.xlarge' => 4, 'm3.2xlarge' => 8,
      'c1.medium' => 2, 'c1.xlarge' => 8,
      'hi1.4xlarge' => 16,
      'cg1.4xlarge' => 8,
      'cc1.4xlarge' => 8, 'cc2.8xlarge' => 16,
      't1.micro' => 0,
      'unknown' => 0,
    }
  end

end
