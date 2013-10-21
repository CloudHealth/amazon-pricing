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
      @instance_types = {}
      @rds_instance_types = {}
    end

    def instance_types
      @instance_types.values
    end

    # Returns whether an instance_type is available. 
    # operating_system = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def instance_type_available?(api_name, type_of_instance = :ondemand, operating_system = :linux)
      instance = @instance_types[api_name]
      return false if instance.nil?
      instance.available?(type_of_instance, operating_system)
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    def add_or_update_instance_type(api_name, name, operating_system, type_of_instance, json)
      current = get_instance_type(api_name)
      if current.nil?
        current = InstanceType.new(self, api_name, name)
        @instance_types[api_name] = current
      end
      current.update_pricing(operating_system, type_of_instance, json)
      current
    end

    def get_instance_type(api_name)
      @instance_types[api_name]
    end
    
    def rds_instance_types
      @rds_instance_types.values
    end

    # Returns whether an instance_type is available. 
    # database_type = :mysql, :oracle, :sqlserver
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def rds_instance_type_available?(api_name, type_of_rds_instance = :ondemand, database_type = :linux)
      instance = @rds_instance_types[api_name]
      return false if instance.nil?
      instance.available?(type_of_rds_instance, database_type)
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    def add_or_update_rds_instance_type(api_name, name, database_type, type_of_rds_instance, json)
      current = get_rds_instance_type(api_name)
      if current.nil?
        current = RdsInstanceType.new(self, api_name, name)
        @rds_instance_types[api_name] = current
      end
      current.update_pricing(database_type, type_of_rds_instance, json)
      current
    end

    def get_rds_instance_type(api_name)
      @rds_instance_types[api_name]
    end    
  end
end