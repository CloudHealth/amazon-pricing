require 'amazon-pricing/definitions/instance-type'

module AwsPricing
  class Ec2InstanceType < InstanceType

    # Returns OperatingSystem pricing
    # e.g. :linux
    def get_operating_system(type)
      get_category_type(type)
    end
    
    # Returns whether an instance_type is available. 
    # operating_system = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def available?(type_of_instance = :ondemand, operating_system = :linux)
      os = get_category_type(operating_system)
      return false if os.nil?
      os.available?(type_of_instance)
    end

    # operating_system = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy, :allupfront, partialupfront, :noupfront
    # term = nil (on demand), yrTerm1, yrTerm3
    def update_pricing_new(operating_system, type_of_instance, price, term = nil, is_prepay = false)
      os = get_category_type(operating_system)
      if os.nil?
        os = OperatingSystem.new(self, operating_system)
        @category_types[operating_system] = os
      end

      p = coerce_price(price)

      if type_of_instance == :ondemand
        os.set_price_per_hour(type_of_instance, nil, p)
      else
        years = :year1 if term == "yrTerm1"
        years = :year3 if term == "yrTerm3"
        if is_prepay
          os.set_prepay(type_of_instance, years, p)
        else
          os.set_price_per_hour(type_of_instance, years, p * 12 / 365 / 24)
        end
      end
    end

    # operating_system = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def update_pricing(operating_system, type_of_instance, json)
      os = get_category_type(operating_system)
      if os.nil?
        os = OperatingSystem.new(self, operating_system)
        @category_types[operating_system] = os
      end

      if type_of_instance == :ondemand
        # e.g. {"size"=>"sm", "valueColumns"=>[{"name"=>"linux", "prices"=>{"USD"=>"0.060"}}]}
        values = Ec2InstanceType::get_values(json, operating_system, true)
        category = operating_system.to_s
        # Someone at AWS is fat fingering the pricing data and putting the text "os" where there should be the actual operating system (e.g. "linux") - see http://a0.awsstatic.com/pricing/1/ec2/linux-od.min.js
        category = "os" if values.has_key?("os")
        price = coerce_price(values[category])
        os.set_price_per_hour(type_of_instance, nil, price)
      else
        json['valueColumns'].each do |val|
          price = coerce_price(val['prices']['USD'])

          case val["name"]
          when "yrTerm1"
            os.set_prepay(type_of_instance, :year1, price)
          when "yrTerm3"
            os.set_prepay(type_of_instance, :year3, price)
          when "yrTerm1Hourly"
            os.set_price_per_hour(type_of_instance, :year1, price)
          when "yrTerm3Hourly"
            os.set_price_per_hour(type_of_instance, :year3, price)
          end
        end
      end
    end

    def update_pricing2(operating_system, res_type, ondemand_pph = nil, year1_prepay = nil, year3_prepay = nil, year1_pph = nil, year3_pph = nil)

      os = get_category_type(operating_system)
      if os.nil?
        os = OperatingSystem.new(self, operating_system)
        @category_types[operating_system] = os
      end

      os.set_price_per_hour(res_type, nil, coerce_price(ondemand_pph)) unless ondemand_pph.nil?
      os.set_prepay(res_type, :year1, coerce_price(year1_prepay)) unless year1_prepay.nil?
      os.set_prepay(res_type, :year3, coerce_price(year3_prepay)) unless year3_prepay.nil?
      os.set_price_per_hour(res_type, :year1, coerce_price(year1_pph)) unless year1_pph.nil?
      os.set_price_per_hour(res_type, :year3, coerce_price(year3_pph)) unless year3_pph.nil?
    end

    # Maintained for backward compatibility reasons
    def operating_systems
      @category_types
    end

    protected
    # Returns [api_name, name]
    def self.get_name(instance_type, api_name, is_reserved = false)
      # Temporary hack: Amazon has released r3 instances but pricing has api_name with asterisk (e.g. "r3.large *")
      api_name.sub!(" *", "")

      # Let's handle new instances more gracefully
      unless @@Name_Lookup.has_key? api_name
        raise UnknownTypeError, "Unknown instance type #{instance_type} #{api_name}", caller
      end

      name = @@Name_Lookup[api_name]

      [api_name, name]
    end

  end
end
