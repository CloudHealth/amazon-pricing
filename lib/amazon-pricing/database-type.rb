module AwsPricing

  class DatabaseType
    attr_accessor :instance_type, :name,

      # Mysql ondemand
      :ondemand_standard_price_per_hour,:ondemand_multiAZ_price_per_hour,

      # Oracle ondemand
      :ondemand_li_standard_price_per_hour, :ondemand_li_multiAZ_price_per_hour,
      :ondemand_byol_standard_price_per_hour, :ondemand_byol_multiAZ_price_per_hour,

      # Sqlserver ondemand
      :ondemand_li_ex_price_per_hour, :ondemand_li_web_price_per_hour, :ondemand_li_se_price_per_hour, :ondemand_byol_price_per_hour,

      # Mysql- reserved
      :standard_light_price_per_hour_1_year, :standard_medium_price_per_hour_1_year, :standard_heavy_price_per_hour_1_year,
      :standard_light_price_per_hour_3_year, :standard_medium_price_per_hour_3_year, :standard_heavy_price_per_hour_3_year,
      :standard_light_prepay_1_year, :standard_light_prepay_3_year, :standard_medium_prepay_1_year, :standard_medium_prepay_3_year, :standard_heavy_prepay_1_year, :standard_heavy_prepay_3_year,
      :multiAZ_light_price_per_hour_1_year, :multiAZ_medium_price_per_hour_1_year, :multiAZ_heavy_price_per_hour_1_year,
      :multiAZ_light_price_per_hour_3_year, :multiAZ_medium_price_per_hour_3_year, :multiAZ_heavy_price_per_hour_3_year,
      :multiAZ_light_prepay_1_year, :multiAZ_light_prepay_3_year, :multiAZ_medium_prepay_1_year, :multiAZ_medium_prepay_3_year, :multiAZ_heavy_prepay_1_year, :multiAZ_heavy_prepay_3_year,

      # Oracle reserved
      :li_standard_light_price_per_hour_1_year, :li_standard_medium_price_per_hour_1_year, :li_standard_heavy_price_per_hour_1_year,
      :li_standard_light_price_per_hour_3_year, :li_standard_medium_price_per_hour_3_year, :li_standard_heavy_price_per_hour_3_year,
      :li_standard_light_prepay_1_year, :li_standard_light_prepay_3_year, :li_standard_medium_prepay_1_year, :li_standard_medium_prepay_3_year, :li_standard_heavy_prepay_1_year, :li_standard_heavy_prepay_3_year,

      :byol_standard_light_price_per_hour_1_year, :byol_standard_medium_price_per_hour_1_year, :byol_standard_heavy_price_per_hour_1_year,
      :byol_standard_light_price_per_hour_3_year, :byol_standard_medium_price_per_hour_3_year, :byol_standard_heavy_price_per_hour_3_year,
      :byol_standard_light_prepay_1_year, :byol_standard_light_prepay_3_year, :byol_standard_medium_prepay_1_year, :byol_standard_medium_prepay_3_year, :byol_standard_heavy_prepay_1_year, :byol_standard_heavy_prepay_3_year,

      :li_multiAZ_light_price_per_hour_1_year, :li_multiAZ_medium_price_per_hour_1_year, :li_multiAZ_heavy_price_per_hour_1_year,
      :li_multiAZ_light_price_per_hour_3_year, :li_multiAZ_medium_price_per_hour_3_year, :li_multiAZ_heavy_price_per_hour_3_year,
      :li_multiAZ_light_prepay_1_year, :li_multiAZ_light_prepay_3_year, :li_multiAZ_medium_prepay_1_year, :li_multiAZ_medium_prepay_3_year, :li_multiAZ_heavy_prepay_1_year, :li_multiAZ_heavy_prepay_3_year,

      :byol_multiAZ_light_price_per_hour_1_year, :byol_multiAZ_medium_price_per_hour_1_year, :byol_multiAZ_heavy_price_per_hour_1_year,
      :byol_multiAZ_light_price_per_hour_3_year, :byol_multiAZ_medium_price_per_hour_3_year, :byol_multiAZ_heavy_price_per_hour_3_year,
      :byol_multiAZ_light_prepay_1_year, :byol_multiAZ_light_prepay_3_year, :byol_multiAZ_medium_prepay_1_year, :byol_multiAZ_medium_prepay_3_year, :byol_multiAZ_heavy_prepay_1_year, :byol_multiAZ_heavy_prepay_3_year,

      # Sqlserver reserved
      :li_ex_light_price_per_hour_1_year, :li_ex_medium_price_per_hour_1_year, :li_ex_heavy_price_per_hour_1_year,
      :li_ex_light_price_per_hour_3_year, :li_ex_medium_price_per_hour_3_year, :li_ex_heavy_price_per_hour_3_year,
      :li_ex_light_prepay_1_year, :li_ex_light_prepay_3_year, :li_ex_medium_prepay_1_year, :li_ex_medium_prepay_3_year, :li_ex_heavy_prepay_1_year, :li_ex_heavy_prepay_3_year,

      :li_web_light_price_per_hour_1_year, :li_web_medium_price_per_hour_1_year, :li_web_heavy_price_per_hour_1_year,
      :li_web_light_price_per_hour_3_year, :li_web_medium_price_per_hour_3_year, :li_web_heavy_price_per_hour_3_year,
      :li_web_light_prepay_1_year, :li_web_light_prepay_3_year, :li_web_medium_prepay_1_year, :li_web_medium_prepay_3_year, :li_web_heavy_prepay_1_year, :li_web_heavy_prepay_3_year,

      :li_se_light_price_per_hour_1_year, :li_se_medium_price_per_hour_1_year, :li_se_heavy_price_per_hour_1_year,
      :li_se_light_price_per_hour_3_year, :li_se_medium_price_per_hour_3_year, :li_se_heavy_price_per_hour_3_year,
      :li_se_light_prepay_1_year, :li_se_light_prepay_3_year, :li_se_medium_prepay_1_year, :li_se_medium_prepay_3_year, :li_se_heavy_prepay_1_year, :li_se_heavy_prepay_3_year,

      :byol_light_price_per_hour_1_year, :byol_medium_price_per_hour_1_year, :byol_heavy_price_per_hour_1_year,
      :byol_light_price_per_hour_3_year, :byol_medium_price_per_hour_3_year, :byol_heavy_price_per_hour_3_year,
      :byol_light_prepay_1_year, :byol_light_prepay_3_year, :byol_medium_prepay_1_year, :byol_medium_prepay_3_year, :byol_heavy_prepay_1_year, :byol_heavy_prepay_3_year


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
    def prepay(type_of_instance = :ondemand, term = nil, deploy_type=nil)
      case type_of_instance
      when :ondemand
        0
      when :light
        if term == :year1
          instance_variable_get("@#{deploy_type}_light_prepay_1_year")
        elsif term == :year3
          instance_variable_get("@#{deploy_type}_light_prepay_3_year")
        end
      when :medium
        if term == :year1
          instance_variable_get("@#{deploy_type}_medium_prepay_1_year")
        elsif term == :year3
          instance_variable_get("@#{deploy_type}_medium_prepay_3_year")
        end
      when :heavy
        if term == :year1
          instance_variable_get("@#{deploy_type}_heavy_prepay_1_year")
        elsif term == :year3
          instance_variable_get("@#{deploy_type}_heavy_prepay_3_year")
        end
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def set_prepay(type_of_instance, term, price, deploy_type)
      case type_of_instance
      when :light
        if term == :year1
          instance_variable_set("@#{deploy_type}_light_prepay_1_year", price)
        elsif term == :year3
          instance_variable_set("@#{deploy_type}_light_prepay_3_year", price)
        end
      when :medium
        if term == :year1
          instance_variable_set("@#{deploy_type}_medium_prepay_1_year", price)
        elsif term == :year3
          instance_variable_set("@#{deploy_type}_medium_prepay_3_year", price)
        end
      when :heavy
        if term == :year1
          instance_variable_set("@#{deploy_type}_heavy_prepay_1_year", price)
        elsif term == :year3
          instance_variable_set("@#{deploy_type}_heavy_prepay_3_year", price)
        end
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def price_per_hour(type_of_instance = :ondemand, term = nil, deploy_type=nil)
      case type_of_instance
        when :ondemand
        instance_variable_get("@ondemand_#{deploy_type}_price_per_hour")
      when :light
        if term == :year1
          instance_variable_get("@#{deploy_type}_light_price_per_hour_1_year")
        elsif term == :year3
          instance_variable_get("@#{deploy_type}_light_price_per_hour_3_year")
        end
      when :medium
        if term == :year1
          instance_variable_get("@#{deploy_type}_medium_price_per_hour_1_year")
        elsif term == :year3
          instance_variable_get("@#{deploy_type}_medium_price_per_hour_3_year")
        end
      when :heavy
        if term == :year1
          instance_variable_get("@#{deploy_type}_heavy_price_per_hour_1_year")
        elsif term == :year3
          instance_variable_get("@#{deploy_type}_heavy_price_per_hour_3_year")
        end
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def set_price_per_hour(type_of_instance, term, price_per_hour, deploy_type)
      case type_of_instance
        when :ondemand
          instance_variable_set("@ondemand_#{deploy_type}_price_per_hour", price_per_hour)
        when :light
        if term == :year1
          instance_variable_set("@#{deploy_type}_light_price_per_hour_1_year", price_per_hour)
        elsif term == :year3
          instance_variable_set("@#{deploy_type}_light_price_per_hour_3_year", price_per_hour)
        end
      when :medium
        if term == :year1
          instance_variable_set("@#{deploy_type}_medium_price_per_hour_1_year", price_per_hour)
        elsif term == :year3
          instance_variable_set("@#{deploy_type}_medium_price_per_hour_3_year", price_per_hour)
        end
      when :heavy
        if term == :year1
          instance_variable_set("@#{deploy_type}_heavy_price_per_hour_1_year", price_per_hour)
        elsif term == :year3
          instance_variable_set("@#{deploy_type}_heavy_price_per_hour_3_year", price_per_hour)
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
      for i in 1..36 do
        on_demand +=  ondemand_pph * 24 * 30.4
        reserved += reserved_pph * 24 * 30.4
        return i if reserved < on_demand
      end
      nil
    end
  end

end
