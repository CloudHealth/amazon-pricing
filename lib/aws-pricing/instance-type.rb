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

  # InstanceType is a specific type of instance in a region with a defined
  # price per hour. The price will vary by platform (Linux, Windows).
  #
  # e.g. m1.large instance in US-East region will cost $0.34/hour for Linux and
  # $0.48/hour for Windows.
  #
  class InstanceType
    attr_accessor :region, :name, :api_name, :linux_price_per_hour, :windows_price_per_hour

    # Initializes and InstanceType object given a region, the internal
    # type (e.g. stdODI) and the json for the specific instance. The json is
    # based on the current undocumented AWS pricing API.
    def initialize(region, instance_type, json)
      values = get_values(json)

      @region = region
      @size = json['size']
      @linux_price_per_hour = values['linux'].to_f
      @linux_price_per_hour = nil if @linux_price_per_hour == 0
      @windows_price_per_hour = values['mswin'].to_f
      @windows_price_per_hour = nil if @windows_price_per_hour == 0
      @instance_type = instance_type

      @api_name = get_api_name(@instance_type, @size)
      @name = get_name(@instance_type, @size)
    end

    # Returns whether an instance_type is available. 
    # Optionally can specify the specific platform (:linix or :windows).
    def available?(platform = nil)
      return @linux_price_per_hour != nil if platform == :linux
      return @windows_price_per_hour != nil if platform == :windows
      return @linux_price_per_hour != nil || @windows_price_per_hour != nil
    end

    def to_s
      "Instance Type: #{@region.name} #{@api_name}, Linux=$#{@linux_price_per_hour}/hour, Windows=$#{@windows_price_per_hour}/hour"
    end

    protected

    attr_accessor :size, :instance_type

    def get_api_name(instance_type, size)
      @@Api_Name_Lookup[instance_type][size]
    end

    def get_name(instance_type, size)
      @@Name_Lookup[instance_type][size]
    end

    # Turn json into hash table for parsing
    def get_values(json)
      values = {}
      json['valueColumns'].each do |val|
        values[val['name']] = val['prices']['USD']
      end
      values
    end


    @@Api_Name_Lookup = {
      'stdODI' => {'sm' => 'm1.small', 'lg' => 'm1.large', 'xl' => 'm1.xlarge'},
      'hiMemODI' => {'xl' => 'm2.xlarge', 'xxl' => 'm2.2xlarge', 'xxxxl' => 'm2.4xlarge'},
      'hiCPUODI' => {'med' => 'c1.medium', 'xl' => 'c1.xlarge'},
      'clusterGPUI' => {'xxxxl' => 'cg1.4xlarge'},
      'clusterComputeI' => {'xxxxl' => 'cc1.4xlarge','xxxxxxxxl' => 'Cluster Compute Eight Extra Large'},
      'uODI' => {'u' => 't1.micro'},
    }
    @@Name_Lookup = {
      'stdODI' => {'sm' => 'Standard Small', 'lg' => 'Standard Large', 'xl' => 'Standard Extra Large'},
      'hiMemODI' => {'xl' => 'Hi-Memory Extra Large', 'xxl' => 'Hi-Memory Double Extra Large', 'xxxxl' => 'Hi-Memory Quadruple Extra Large'},
      'hiCPUODI' => {'med' => 'High-CPU Medium', 'xl' => 'High-CPU Extra Large'},
      'clusterGPUI' => {'xxxxl' => 'Cluster GPU Quadruple Extra Large'},
      'clusterComputeI' => {'xxxxl' => 'Cluster Compute Quadruple Extra Large', 'xxxxxxxxl' => 'Cluster Compute Eight Extra Large'},
      'uODI' => {'u' => 'Micro'},
    }
  end

end
