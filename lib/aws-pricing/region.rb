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
  # Region represents a geographic area in which Amazon Web Services has
  # one or more data centers. Different regions will offer difference services
  # and pricing.
  #
  # e.g. us-east, us-west
  #
  class Region
    attr_accessor :name

    def initialize(name)
      @name = name
      @_ec2_on_demand_instance_types = {}
      @_ec2_reserved_instance_types = {}
    end

    def ec2_on_demand_instance_types
      @_ec2_on_demand_instance_types.values
    end
    
    def ec2_reserved_instance_types
      @_ec2_reserved_instance_types.values
    end

    # Returns whether an instance_type is available. Must specify the type
    # (:on_demand or :reserved) and instance type (m1.large). Optionally can
    # specify the specific platform (:linix or :windows).
    def instance_type_available?(type, api_name, platform = nil)
      get_instance_type(type, api_name).available?(platform)
    end

    # Type = :on_demand or :reserved
    def add_instance_type(type, instance_type)
      raise "Instance type #{instance_type.api_name} in region #{@name} already exists" if get_instance_type(type, instance_type.api_name)
      if type == :on_demand
        @_ec2_on_demand_instance_types[instance_type.api_name] = instance_type
      elsif type == :reserved
        @_ec2_reserved_instance_types[instance_type.api_name] = instance_type
      end
    end

    # Type = :on_demand or :reserved
    def get_instance_type(type, api_name)
      if type == :on_demand
        @_ec2_on_demand_instance_types[api_name]
      elsif type == :reserved
        @_ec2_reserved_instance_types[api_name]
      else
        nil
      end
    end

    protected

    attr_accessor :_ec2_on_demand_instance_types, :_ec2_reserved_instance_types

  end

end