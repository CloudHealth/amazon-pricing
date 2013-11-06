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

  class DatabaseType < CategoryType
    attr_accessor :ondemand_multi_az_price_per_hour,
          :multi_az_light_price_per_hour_1_year, :multi_az_medium_price_per_hour_1_year, :multi_az_heavy_price_per_hour_1_year,
          :multi_az_light_price_per_hour_3_year, :multi_az_medium_price_per_hour_3_year, :multi_az_heavy_price_per_hour_3_year,
          :multi_az_light_prepay_1_year, :multi_az_light_prepay_3_year, :multi_az_medium_prepay_1_year, :multi_az_medium_prepay_3_year, :multi_az_heavy_prepay_1_year, :multi_az_heavy_prepay_3_year


    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def prepay(type_of_instance = :ondemand, term = nil, is_multi_az = false)
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
        super(type_of_instance, term)
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def set_prepay(type_of_instance, is_multi_az = false, term, price)
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
        super(type_of_instance,term,price)
      end      
    end

    #type_of_instance = :ondemand, :light, :medium, :heavy
    #term = :year_1, :year_3, nil
    def price_per_hour(type_of_instance = :ondemand, term = nil, is_multi_az = false)
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
        super(type_of_instance,term)
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def set_price_per_hour(type_of_instance, is_multi_az = false, term, price_per_hour)
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
        super(type_of_instance,term,price_per_hour)
      end
    end
  end
end
