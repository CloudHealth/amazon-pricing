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
    attr_accessor :rds_instance_type, :name, 
      :ondemand_price_per_hour, :light_price_per_hour_1_year, :medium_price_per_hour_1_year, :heavy_price_per_hour_1_year,
      :light_price_per_hour_3_year, :medium_price_per_hour_3_year, :heavy_price_per_hour_3_year,
      :light_prepay_1_year, :light_prepay_3_year, :medium_prepay_1_year, :medium_prepay_3_year, :heavy_prepay_1_year, :heavy_prepay_3_year


    def initialize(rds_instance_type, name)
      @rds_instance_type = rds_instance_type
      @name = name
    end

    # Returns whether an rds_instance_type is available. 
    # type_of_rds_instance = :ondemand, :light, :medium, :heavy
    def available?(type_of_rds_instance = :ondemand)
      not price_per_hour(type_of_rds_instance).nil?
    end

    # type_of_rds_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def prepay(type_of_rds_instance = :ondemand, term = nil)
      case type_of_rds_instance
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

    # type_of_rds_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def set_prepay(type_of_rds_instance, term, price)
      case type_of_rds_instance
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

    # type_of_rds_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def price_per_hour(type_of_rds_instance = :ondemand, term = nil)
      case type_of_rds_instance
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

    # type_of_rds_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def set_price_per_hour(type_of_rds_instance, term, price_per_hour)
      case type_of_rds_instance
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

    # type_of_rds_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def get_breakeven_month(type_of_rds_instance, term)
      # Some regions and types do not have reserved available
      ondemand_pph = price_per_hour(:ondemand)
      reserved_pph = price_per_hour(type_of_rds_instance, term)
      return nil if ondemand_pph.nil? || reserved_pph.nil?

      on_demand = 0
      reserved = prepay(type_of_rds_instance, term)
      for i in 1..36 do
        on_demand +=  ondemand_pph * 24 * 30.4 
        reserved += reserved_pph * 24 * 30.4 
        return i if reserved < on_demand
      end
      nil
    end

  end

end
