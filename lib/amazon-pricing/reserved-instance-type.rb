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
    attr_accessor :prepay_1_year, :prepay_3_year

    # Initializes and InstanceType object given a region, the internal
    # type (e.g. stdODI) and the json for the specific instance. The json is
    # based on the current undocumented AWS pricing API.
    def initialize(region, instance_type, json)
      super(region, instance_type, json)

      # Fixme: calling twice, fix later
      values = get_values(json)

      @prepay_1_year = values['yrTerm1'].to_f unless values['yrTerm1'].to_f == 0
      @prepay_3_year = values['yrTerm3'].to_f unless values['yrTerm3'].to_f == 0
    end

    def to_s
      "Reserved Instance Type: #{@region.name} #{@api_name}, 1 Year Prepay=#{@prepay_1_year}, 3 Year Prepay=#{@prepay_3_year}, Linux=$#{@linux_price_per_hour}/hour, Windows=$#{@windows_price_per_hour}/hour"
    end

    protected
      attr_accessor :size, :instance_type

      def get_api_name(instance_type, size)
        @@Api_Name_Lookup_Reserved[instance_type][size]
      end

      def get_name(instance_type, size)
        @@Name_Lookup_Reserved[instance_type][size]
      end

      @@Api_Name_Lookup_Reserved = {
        'stdResI' => {'sm' => 'm1.small', 'lg' => 'm1.large', 'xl' => 'm1.xlarge'},
        'hiMemResI' => {'xl' => 'm2.xlarge', 'xxl' => 'm2.2xlarge', 'xxxxl' => 'm2.4xlarge'},
        'hiCPUResI' => {'med' => 'c1.medium', 'xl' => 'c1.xlarge'},
        'clusterGPUResI' => {'xxxxl' => 'cg1.4xlarge'},
        'clusterCompResI' => {'xxxxl' => 'cc1.4xlarge', 'xxxxxxxxl' => 'Cluster Compute Eight Extra Large'},
        'uResI' => {'u' => 't1.micro'},
      }
      @@Name_Lookup_Reserved = {
        'stdResI' => {'sm' => 'Standard Small', 'lg' => 'Standard Large', 'xl' => 'Standard Extra Large'},
        'hiMemResI' => {'xl' => 'Hi-Memory Extra Large', 'xxl' => 'Hi-Memory Double Extra Large', 'xxxxl' => 'Hi-Memory Quadruple Extra Large'},
        'hiCPUResI' => {'med' => 'High-CPU Medium', 'xl' => 'High-CPU Extra Large'},
        'clusterGPUResI' => {'xxxxl' => 'Cluster GPU Quadruple Extra Large'},
        'clusterCompResI' => {'xxxxl' => 'Cluster Compute Quadruple Extra Large', 'xxxxxxxxl' => 'Cluster Compute Eight Extra Large'},
        'uResI' => {'u' => 'Micro'},
      }
  end

end
