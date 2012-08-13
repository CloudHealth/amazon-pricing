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
  # Region represents a geographic area in which Amazon Web Services has
  # one or more data centers. Different regions will offer difference services
  # and pricing.
  #
  # e.g. us-east, us-west
  #
  class Region
    attr_accessor :name, :ebs_price

    def initialize(name)
      @name = name
      @_ec2_on_demand_instance_types = {}
      @_ec2_reserved_instance_types_light = {}
      @_ec2_reserved_instance_types_medium = {}
      @_ec2_reserved_instance_types_heavy = {}
    end

    def ec2_on_demand_instance_types
      @_ec2_on_demand_instance_types.values
    end

    # reserved_usage_type = :light, :medium, :heavy
    def ec2_reserved_instance_types(reserved_usage_type = nil)
      case reserved_usage_type
      when :light
        @_ec2_reserved_instance_types_light.values
      when :medium
        @_ec2_reserved_instance_types_medium.values
      when :heavy
        @_ec2_reserved_instance_types_heavy.values
      else
        @_ec2_reserved_instance_types_light.values << @_ec2_reserved_instance_types_medium.values << @_ec2_reserved_instance_types_heavy.values
      end
    end

    # Returns whether an instance_type is available. Must specify the type
    # (:on_demand or :reserved) and instance type (m1.large). Optionally can
    # specify the specific platform (:linix or :windows).
    def instance_type_available?(type, api_name, platform = nil)
      get_instance_type(type, api_name).available?(platform)
    end

    # instance_type = :on_demand or :reserved
    # reserved_usage_type = :light, :medium, :heavy
    def add_instance_type(type, instance_type, reserved_usage_type = :medium)
      raise "Instance type #{instance_type.api_name} in region #{@name} already exists" if get_instance_type(type, instance_type.api_name, reserved_usage_type)
      if type == :on_demand
        @_ec2_on_demand_instance_types[instance_type.api_name] = instance_type
      elsif type == :reserved
        case reserved_usage_type
        when :light
          @_ec2_reserved_instance_types_light[instance_type.api_name] = instance_type
        when :medium
          @_ec2_reserved_instance_types_medium[instance_type.api_name] = instance_type
        when :heavy
          @_ec2_reserved_instance_types_heavy[instance_type.api_name] = instance_type
        end
      end
    end

    # Type = :on_demand or :reserved
    # reserved_usage_type = :light, :medium, :heavy
    def get_instance_type(type, api_name, reserved_usage_type = :medium)
      if type == :on_demand
        @_ec2_on_demand_instance_types[api_name]
      elsif type == :reserved
        case reserved_usage_type
        when :light
          @_ec2_reserved_instance_types_light[api_name]
        when :medium
          @_ec2_reserved_instance_types_medium[api_name]
        when :heavy
          @_ec2_reserved_instance_types_heavy[api_name]
        end
      else
        nil
      end
    end

    protected

    attr_accessor :_ec2_on_demand_instance_types, :_ec2_reserved_instance_types_light, :_ec2_reserved_instance_types_medium, :_ec2_reserved_instance_types_heavy

  end

end