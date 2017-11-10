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

  class CategoryType
    attr_accessor :instance_type, :name, 
      :ondemand_price_per_hour, :light_price_per_hour_1_year, :medium_price_per_hour_1_year, :heavy_price_per_hour_1_year,
      :light_price_per_hour_3_year, :medium_price_per_hour_3_year, :heavy_price_per_hour_3_year,
      :light_prepay_1_year, :light_prepay_3_year, :medium_prepay_1_year, :medium_prepay_3_year, :heavy_prepay_1_year, :heavy_prepay_3_year,
      :allupfront_prepay_1_year, :allupfront_prepay_3_year,
      :partialupfront_price_per_hour_1_year, :partialupfront_prepay_1_year, :partialupfront_price_per_hour_3_year, :partialupfront_prepay_3_year,
      :noupfront_price_per_hour_1_year, :noupfront_price_per_hour_3_year,
      :convertible_allupfront_prepay_3_year,
        :convertible_partialupfront_price_per_hour_3_year, :convertible_partialupfront_prepay_3_year,
        :convertible_noupfront_price_per_hour_3_year,
      :convertible_allupfront_prepay_1_year,
        :convertible_partialupfront_price_per_hour_1_year, :convertible_partialupfront_prepay_1_year,
        :convertible_noupfront_price_per_hour_1_year

    def allupfront_effective_rate_1_year
      (allupfront_prepay_1_year / 365 / 24).round(4)
    end

    def allupfront_effective_rate_3_year
      (allupfront_prepay_3_year / 3 / 365 / 24).round(4)
    end

    def partialupfront_effective_rate_1_year
      (partialupfront_prepay_1_year / 365 / 24 + partialupfront_price_per_hour_1_year).round(4)
    end

    def partialupfront_effective_rate_3_year
      (partialupfront_prepay_3_year / 3 / 365 / 24 + partialupfront_price_per_hour_3_year).round(4)
    end

    def noupfront_effective_rate_1_year
      (noupfront_price_per_hour_1_year).round(4)
    end

    def initialize(instance_type=nil, name=nil)
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
    def prepay(type_of_instance = :ondemand, term = nil)
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
      when :allupfront
        if term == :year1
          @allupfront_prepay_1_year
        elsif term == :year1_convertible
          @convertible_allupfront_prepay_1_year
        elsif term == :year3
          @allupfront_prepay_3_year
        elsif term == :year3_convertible
          @convertible_allupfront_prepay_3_year
        end
      when :partialupfront
        if term == :year1
          @partialupfront_prepay_1_year
        elsif term == :year1_convertible
          @convertible_partialupfront_prepay_1_year
        elsif term == :year3
          @partialupfront_prepay_3_year
        elsif term == :year3_convertible
          @convertible_partialupfront_prepay_3_year
        end
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year1, :year3, nil
    def set_prepay(type_of_instance, term, price)
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
      when :allupfront
        if term == :year1
          @allupfront_prepay_1_year = price
        elsif term == :year1_convertible
          @convertible_allupfront_prepay_1_year = price
        elsif term == :year3
          @allupfront_prepay_3_year = price
        elsif term == :year3_convertible
          @convertible_allupfront_prepay_3_year = price
        end
      when :partialupfront
        if term == :year1
          @partialupfront_prepay_1_year = price
        elsif term == :year1_convertible
          @convertible_partialupfront_prepay_1_year = price
        elsif term == :year3
          @partialupfront_prepay_3_year = price
        elsif term == :year3_convertible
          @convertible_partialupfront_prepay_3_year = price
        end
      else
        raise "Unable to set prepay for #{instance_type.api_name} : #{name} : #{type_of_instance} : #{term} to #{price}"
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year1, :year3, nil
    def price_per_hour(type_of_instance = :ondemand, term = nil)
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
      when :partialupfront
        if term == :year1
          @partialupfront_price_per_hour_1_year
        elsif term == :year1_convertible
          @convertible_partialupfront_price_per_hour_1_year
        elsif term == :year3
          @partialupfront_price_per_hour_3_year
        elsif term == :year3_convertible
          @convertible_partialupfront_price_per_hour_3_year
        end
      when :noupfront
        if term == :year1
          @noupfront_price_per_hour_1_year
        elsif term == :year1_convertible
          @convertible_noupfront_price_per_hour_1_year
        elsif term == :year3
          @noupfront_price_per_hour_3_year
        elsif term == :year3_convertible
          @convertible_noupfront_price_per_hour_3_year
        end
      when :allupfront
        0
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def set_price_per_hour(type_of_instance, term, price_per_hour)
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
      when :partialupfront
        if term == :year1
          @partialupfront_price_per_hour_1_year = price_per_hour
        elsif term == :year1_convertible
          @convertible_partialupfront_price_per_hour_1_year = price_per_hour
        elsif term == :year3
          @partialupfront_price_per_hour_3_year = price_per_hour
        elsif term == :year3_convertible
          @convertible_partialupfront_price_per_hour_3_year = price_per_hour
        end
      when :noupfront
        if term == :year1
          @noupfront_price_per_hour_1_year = price_per_hour
        elsif term == :year1_convertible
          @convertible_noupfront_price_per_hour_1_year = price_per_hour
        elsif term == :year3
          @noupfront_price_per_hour_3_year = price_per_hour
        elsif term == :year3_convertible
          @convertible_noupfront_price_per_hour_3_year = price_per_hour
        end
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def get_breakeven_month(type_of_instance, term)
      # Some regions and types do not have reserved available
      ondemand_pph = price_per_hour(:ondemand)
      reserved_pph = price_per_hour(type_of_instance, term)
      return nil if ondemand_pph.nil? || reserved_pph.nil?

      on_demand = 0
      reserved = prepay(type_of_instance, term)
      return nil if reserved.nil?

      for i in 1..36 do
        on_demand +=  ondemand_pph * 24 * 30.4 
        reserved += reserved_pph * 24 * 30.4 
        return i if reserved < on_demand
      end
      nil
    end
  end
end
