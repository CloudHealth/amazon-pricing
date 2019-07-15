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
        case term
          when "yrTerm1", "yrTerm1Standard"
            years = :year1
          when "yrTerm1Convertible"
            years = :year1_convertible
          when "yrTerm3", "yrTerm3Standard"
            years = :year3
          when "yrTerm3Convertible"
            years = :year3_convertible
          else
            $stderr.puts "[#{__method__}] WARNING: unknown term:#{term} os:#{operating_system},type:#{type_of_instance},prepay:#{is_prepay}"
        end
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
          when "yrTerm1", "yrTerm1Standard"
            os.set_prepay(type_of_instance, :year1, price)
          when "yrTerm3", "yrTerm3Standard"
            os.set_prepay(type_of_instance, :year3, price)
          when "yrTerm1Hourly"
            os.set_price_per_hour(type_of_instance, :year1, price)
          when "yrTerm3Hourly"
            os.set_price_per_hour(type_of_instance, :year3, price)
          else
            $stderr.puts "[#{__method__}] WARNING: unknown term:#{val["name"]}"
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

    def self.get_network_mbps(throughput)
      network_mbps = @Network_Throughput_MBits_Per_Second[throughput]
      if not network_mbps
        $stderr.puts "Unknown network throughput for #{throughput}"
      end
      network_mbps
    end

    # Take in string from amazon pricing api, return network properties
    # Input: String containing network capacity from amazon-pricing-api
    # Output: network throughput as a string, int containing network mbps
    def self.get_network_information(network_string)
      throughput = @Network_String_To_Sym[network_string]
      if throughput.nil?
          $stderr.puts "[#{__method__}] WARNING: unknown network throughput string:#{network_string}"
      end
      network_mbps = @Network_Throughput_MBits_Per_Second[throughput]
      [throughput.to_s, network_mbps]
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

    def self.get_network_capacity_descriptions
      return @Network_Capacity_Descriptions
    end

    # throughput values for performance ratings
    # Amazon informally tells customers that they translate as follows:
    #   Low = 100 Mbps
    #   Medium = 500 Mbps
    #   High = 1 Gbps
    #   10Gig = 10 Gbps (obviously)
    @Network_Throughput_MBits_Per_Second = {
        :very_low => 50,
        :low => 100,
        :low_to_moderate => 250,
        :moderate => 500,
        :high => 1000,
        :ten_gigabit => 10000,
        :twelve_gigabit => 12000,
        :twenty_gigabit => 20000,
        :twentyfive_gigabit => 25000, # presumes ENA
        :fifty_gigabit => 50000,
        :one_hundred_gigabit => 100000
    }

    # Use in population of profiles, takes in string value that amazon uses to reflect network capacity
    # Returns symbol we use to map to numeric value
    @Network_String_To_Sym = {
        'Very Low' => :very_low,
        'Low' => :low,
        'Low to Moderate' => :low_to_moderate,
        'Moderate' => :moderate,
        'High' => :high,
        '10,000 Mbps' => :ten_gigabit,
        'Up to 10,000 Mbps' => :ten_gigabit,
        '10 Gigabit'=> :ten_gigabit,
        '12 Gigabit'=> :twelve_gigabit,
        'Up to 10 Gigabit' => :ten_gigabit,
        '20 Gigabit' => :twenty_gigabit,
        'Up to 25 Gigabit' => :twentyfive_gigabit,
        '25,000 Mbps' => :twentyfive_gigabit,
        '25 Gigabit' => :twentyfive_gigabit,
        '50 Gigabit' => :fifty_gigabit,
        '100 Gigabit' => :one_hundred_gigabit
    }

    @Network_Capacity_Descriptions = ActiveSupport::HashWithIndifferentAccess.new(
        very_low: "Very Low",
        low: "Low",
        low_to_moderate: "Low to Moderate",
        moderate: "Moderate",
        high: "High",
        ten_gigabit: "10 Gigabit",
        twentyfive_gigabit: "25 Gigabit",
        twenty_gigabit: "20 Gigabit",
        fifty_gigabit: "50 Gigabit"
    ).freeze

  end
end
