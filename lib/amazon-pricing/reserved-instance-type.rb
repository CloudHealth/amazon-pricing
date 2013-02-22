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

  # ReservedInstanceType is a specific type of instance reservation in a region
  # with a defined price per hour, and a reservation term of 1 or 3 years. The
  # price will vary by platform (Linux, Windows), and as of December 2012,
  # reserved instances have three usage types: light, medium and heavy.
  #
  class ReservedInstanceType < InstanceType
    attr_accessor :prepay_1_year, :prepay_3_year, :usage_type, :linux_price_per_hour_3_year, :windows_price_per_hour_3_year

    # Initializes and InstanceType object given a region, the internal
    # type (e.g. stdODI) and the json for the specific instance. The json is
    # based on the current undocumented AWS pricing API.
    def initialize(region, instance_type, json, usage_type, platform)
      super(region, instance_type, json)

      # Fixme: calling twice, fix later
      json['valueColumns'].each do |val|
        case val["name"]
        when "yrTerm1"
          @prepay_1_year = val['prices']['USD'].to_f unless val['prices']['USD'].to_f == 0
        when "yrTerm1Hourly"
          if platform == :windows
            @windows_price_per_hour = val['prices']['USD']
          elsif platform == :linux
            @linux_price_per_hour = val['prices']['USD']
          end
        when "yrTerm3"
          @prepay_3_year = val['prices']['USD'].to_f unless val['prices']['USD'].to_f == 0
        when "yrTerm3Hourly"
          if platform == :windows
            @windows_price_per_hour_3_year = val['prices']['USD']
          elsif platform == :linux
            @linux_price_per_hour_3_year = val['prices']['USD']
          end
        end
      end
      @usage_type = usage_type
    end

    def linux_price_per_hour_1_year
      self.linux_price_per_hour
    end

    def windows_price_per_hour_1_year
      self.windows_price_per_hour
    end

    def to_s
      "Reserved Instance Type: #{@region.name} #{@api_name}, 1 Year Prepay=#{@prepay_1_year}, 3 Year Prepay=#{@prepay_3_year}, Linux=$#{@linux_price_per_hour}/hour, Windows=$#{@windows_price_per_hour}/hour"
    end

    def is_reserved?
      true
    end

    def update(instance_type)
      super
      # Due to new AWS json we have to make two passes through to populate an instance
      @linux_price_per_hour_3_year = instance_type.linux_price_per_hour_3_year if @linux_price_per_hour_3_year.nil?
      @windows_price_per_hour_3_year = instance_type.windows_price_per_hour_3_year if @windows_price_per_hour_3_year.nil?
    end

    protected
      attr_accessor :size, :instance_type

      def self.get_api_name(instance_type, size)
        # Let's handle new instances more gracefully
        unless @@Api_Name_Lookup_Reserved.has_key? instance_type
          raise UnknownTypeError, "Unknown instance type #{instance_type}", caller
        else
          @@Api_Name_Lookup_Reserved[instance_type][size]
        end
      end

      def self.get_name(instance_type, size)
        @@Name_Lookup_Reserved[instance_type][size]
      end

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
  end

end
