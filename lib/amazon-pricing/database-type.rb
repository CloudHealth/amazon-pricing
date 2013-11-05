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

  class DatabaseType
    attr_accessor :instance_type, :name, 
      :ondemand_price_per_hour, :ondemand_multi_az_price_per_hour,
      :light_price_per_hour_1_year, :medium_price_per_hour_1_year, :heavy_price_per_hour_1_year,
      :light_price_per_hour_3_year, :medium_price_per_hour_3_year, :heavy_price_per_hour_3_year,
      :light_prepay_1_year, :light_prepay_3_year, :medium_prepay_1_year, :medium_prepay_3_year, :heavy_prepay_1_year, :heavy_prepay_3_year,
      :multi_az_light_price_per_hour_1_year, :multi_az_medium_price_per_hour_1_year, :multi_az_heavy_price_per_hour_1_year,
      :multi_az_light_price_per_hour_3_year, :multi_az_medium_price_per_hour_3_year, :multi_az_heavy_price_per_hour_3_year,
      :multi_az_light_prepay_1_year, :multi_az_light_prepay_3_year, :multi_az_medium_prepay_1_year, :multi_az_medium_prepay_3_year, :multi_az_heavy_prepay_1_year, :multi_az_heavy_prepay_3_year


    def initialize(instance_type, name)
      @instance_type = instance_type
      @name = name
    end

    # Returns whether an instance_type is available. 
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def available?(type_of_instance = :ondemand)
      not price_per_hour(type_of_instance).nil?
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def prepay(type_of_instance = :ondemand, term = nil, is_multi_az)
      if is_multi_az
        case type_of_instance
        when :ondemand
          0
        when :light
          if term == :year1
            @multi_az_light_prepay_1_year
          elsif term == :year3
            @multi_az_light_prepay_3_year
          end
        when :medium
          if term == :year1
            @multi_az_medium_prepay_1_year
          elsif term == :year3
            @multi_az_medium_prepay_3_year
          end
        when :heavy
          if term == :year1
            @multi_az_heavy_prepay_1_year
          elsif term == :year3
            @multi_az_heavy_prepay_3_year
          end
        end
      else
        case type_of_instance
        when :ondemand
          0
        when :light
          if term == :year1
            @light_prepay_1_year
          elsif term == :year3
            @light_prepay_3_year
          end
        when :medium
          if term == :year1
            @medium_prepay_1_year
          elsif term == :year3
            @medium_prepay_3_year
          end
        when :heavy
          if term == :year1
            @heavy_prepay_1_year
          elsif term == :year3
            @heavy_prepay_3_year
          end
        end
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def set_prepay(type_of_instance, is_multi_az, term, price)
      if is_multi_az
        case type_of_instance
        when :light
          if term == :year1
            @multi_az_light_prepay_1_year = price
          elsif term == :year3
            @multi_az_light_prepay_3_year = price
          end
        when :medium
          if term == :year1
            @multi_az_medium_prepay_1_year = price
          elsif term == :year3
            @multi_az_medium_prepay_3_year = price
          end
        when :heavy
          if term == :year1
            @multi_az_heavy_prepay_1_year = price
          elsif term == :year3
            @multi_az_heavy_prepay_3_year = price
          end
        end        
      else
        case type_of_instance
        when :light
          if term == :year1
            @light_prepay_1_year = price
          elsif term == :year3
            @light_prepay_3_year = price
          end
        when :medium
          if term == :year1
            @medium_prepay_1_year = price
          elsif term == :year3
            @medium_prepay_3_year = price
          end
        when :heavy
          if term == :year1
            @heavy_prepay_1_year = price
          elsif term == :year3
            @heavy_prepay_3_year = price
          end
        end
      end      
    end

    type_of_instance = :ondemand, :light, :medium, :heavy
    term = :year_1, :year_3, nil
    def price_per_hour(type_of_instance = :ondemand, term = nil, is_multi_az)
      if is_multi_az
        case type_of_instance
        when :ondemand
          @multi_az_ondemand_price_per_hour
        when :light
          if term == :year1
            @multi_az_light_price_per_hour_1_year
          elsif term == :year3
            @multi_az_light_price_per_hour_3_year
          end
        when :medium
          if term == :year1
            @multi_az_medium_price_per_hour_1_year
          elsif term == :year3
            @multi_az_medium_price_per_hour_3_year
          end
        when :heavy
          if term == :year1
            @multi_az_heavy_price_per_hour_1_year
          elsif term == :year3
            @multi_az_heavy_price_per_hour_3_year
          end
        end
      else
        case type_of_instance
        when :ondemand
          @ondemand_price_per_hour
        when :light
          if term == :year1
            @light_price_per_hour_1_year
          elsif term == :year3
            @light_price_per_hour_3_year
          end
        when :medium
          if term == :year1
            @medium_price_per_hour_1_year
          elsif term == :year3
            @medium_price_per_hour_3_year
          end
        when :heavy
          if term == :year1
            @heavy_price_per_hour_1_year
          elsif term == :year3
            @heavy_price_per_hour_3_year
          end
        end
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def set_price_per_hour(type_of_instance, is_multi_az, term, price_per_hour)
      if is_multi_az
        case type_of_instance
        when :ondemand
          @multi_az_ondemand_price_per_hour = price_per_hour
        when :light
          if term == :year1
            @multi_az_light_price_per_hour_1_year = price_per_hour
          elsif term == :year3
            @multi_az_light_price_per_hour_3_year = price_per_hour
          end
        when :medium
          if term == :year1
            @multi_az_medium_price_per_hour_1_year = price_per_hour
          elsif term == :year3
            @multi_az_medium_price_per_hour_3_year = price_per_hour
          end
        when :heavy
          if term == :year1
            @multi_az_heavy_price_per_hour_1_year = price_per_hour
          elsif term == :year3
            @multi_az_heavy_price_per_hour_3_year = price_per_hour
          end
        end
      else
        case type_of_instance
        when :ondemand
          @ondemand_price_per_hour = price_per_hour
        when :light
          if term == :year1
            @light_price_per_hour_1_year = price_per_hour
          elsif term == :year3
            @light_price_per_hour_3_year = price_per_hour
          end
        when :medium
          if term == :year1
            @medium_price_per_hour_1_year = price_per_hour
          elsif term == :year3
            @medium_price_per_hour_3_year = price_per_hour
          end
        when :heavy
          if term == :year1
            @heavy_price_per_hour_1_year = price_per_hour
          elsif term == :year3
            @heavy_price_per_hour_3_year = price_per_hour
          end
        end        
      end
    end
  end
end
