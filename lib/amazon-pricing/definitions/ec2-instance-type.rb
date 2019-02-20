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

    # operating_system = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # dhprice is a string representing the price per hour for the Dedicated Host
    # capacity is the number of this type of instancess supported on this Dedicated Host
    def update_dhi_pricing(operating_system, dhprice, capacity)
      os = get_category_type(operating_system)
      if os.nil?
        os = OperatingSystem.new(self, operating_system)
        @category_types[operating_system] = os
      end

      category = operating_system.to_s
      values = { category => dhprice }
      price = coerce_price(values[category])
      os.set_price_per_hour(:ondemand, nil, price/capacity)
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

    # aws does not provide any json-sourced network_capacity, so for now we provide this hardcoded lookup
    # see https://aws.amazon.com/ec2/instance-types/, under 'Instance Types Matrix', under 'Networking Performance'
    def self.get_network_capacity(api_name)
      throughput = @Network_Performance[api_name]
      if not throughput
        $stderr.puts "Unknown network throughput for instance type #{api_name}"
      end
      throughput
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
        :twenty_gigabit => 20000,
        :twentyfive_gigabit => 25000, # presumes ENA
        :fifty_gigabit => 50000,
        :one_hundred_gigabit => 100000
    }

    # Use in population of profiles, takes in string value that amazon uses to reflect network capacity
    # Returns symbol we use to map to numeric value
    @Network_String_To_Sym = {
        'Very Low' =>  :very_low,
        'Low' => :low,
        'Low to Moderate' => :low_to_moderate,
        'Moderate' => :moderate,
        'High' => :high,
        '10 Gigabit'=> :ten_gigabit,
        'Up to 10 Gigabit' => :ten_gigabit,
        '20 Gigabit' => :twenty_gigabit,
        'Up to 25 Gigabit' => :twentyfive_gigabit,
        '25 Gigabit' => :twentyfive_gigabit,
        '50 Gigabit' => :fifty_gigabit,
        '100 Gigabit' => :one_hundred_gigabit
    }

    # handy summary here: www.ec2instances.info
    @Network_Performance = {
      'a1.medium' => :ten_gigabit, # up to 10G
      'a1.large' => :ten_gigabit, # up to 10G
      'a1.xlarge' => :ten_gigabit, # up to 10G
      'a1.2xlarge' => :ten_gigabit, # up to 10G
      'a1.4xlarge' => :ten_gigabit, # up to 10G
      'c1.medium' => :moderate,
      'c1.xlarge' => :high,
      'c3.2xlarge' => :high,
      'c3.4xlarge' => :high,
      'c3.8xlarge' => :ten_gigabit,
      'c3.large' => :moderate,
      'c3.xlarge' => :moderate,
      'c4.2xlarge' => :high,
      'c4.4xlarge' => :high,
      'c4.8xlarge' => :ten_gigabit,
      'c4.large' => :moderate,
      'c4.xlarge' => :high,
      'c5.18xlarge' => :twentyfive_gigabit,
      'c5.2xlarge' => :ten_gigabit, # upto 10G
      'c5.4xlarge' => :ten_gigabit, # upto 10G
      'c5.9xlarge' => :ten_gigabit,
      'c5.large' => :ten_gigabit,   # upto 10G
      'c5.xlarge' => :ten_gigabit,  # upto 10G
      'c5d.18xlarge' => :twentyfive_gigabit,
      'c5d.2xlarge' => :ten_gigabit, # upto 10G
      'c5d.4xlarge' => :ten_gigabit, # upto 10G
      'c5d.9xlarge' => :ten_gigabit,
      'c5d.large' => :ten_gigabit,   # upto 10G
      'c5d.xlarge' => :ten_gigabit,  # upto 10G
      'c5n.large' => :twentyfive_gigabit, # up to 25gb
      'c5n.xlarge' => :twentyfive_gigabit, # up to 25gb
      'c5n.2xlarge' => :twentyfive_gigabit, # up to 25gb
      'c5n.4xlarge' => :twentyfive_gigabit, # up to 25gb
      'c5n.9xlarge' => :fifty_gigabit,
      'c5n.18xlarge' => :one_hundred_gigabit,
      'cache.c1.xlarge' => :high,
      'cache.m1.large' => :moderate,
      'cache.m1.medium' => :moderate,
      'cache.m1.small' => :low,
      'cache.m1.xlarge' => :high,
      'cache.m2.2xlarge' => :moderate,
      'cache.m2.4xlarge' => :high,
      'cache.m2.xlarge' => :moderate,
      'cache.m3.2xlarge' => :high,
      'cache.m3.large' => :moderate,
      'cache.m3.medium' => :moderate,
      'cache.m3.xlarge' => :high,
      'cache.m4.large' => :moderate,
      'cache.m4.xlarge' => :high,
      'cache.m4.2xlarge' => :high,
      'cache.m4.4xlarge' => :high,
      'cache.m4.10xlarge' => :ten_gigabit,
      'cache.r3.2xlarge' => :high,
      'cache.r3.4xlarge' => :high,
      'cache.r3.8xlarge' => :ten_gigabit,
      'cache.r3.large' => :moderate,
      'cache.r3.xlarge' => :moderate,
      'cache.r4.16xlarge' => :twentyfive_gigabit,
      'cache.r4.2xlarge' => :ten_gigabit, # upto 10G
      'cache.r4.4xlarge' => :ten_gigabit, # upto 10G
      'cache.r4.8xlarge' => :ten_gigabit,
      'cache.r4.large' => :ten_gigabit,   # upto 10G
      'cache.r4.xlarge' => :ten_gigabit,  # upto 10G
      'cache.x1.16xlarge' => :ten_gigabit,
      'cache.x1.32xlarge' => :ten_gigabit,
      'cache.t1.micro' => :very_low,
      'cache.t2.medium' => :low_to_moderate,
      'cache.t2.micro' => :low_to_moderate,
      'cache.t2.small' => :low_to_moderate,
      'cc1.4xlarge' => :ten_gigabit,
      'cc2.8xlarge' => :ten_gigabit,
      'cg1.4xlarge' => :ten_gigabit,
      'cr1.8xlarge' => :ten_gigabit,
      'd2.2xlarge' => :high,
      'd2.4xlarge' => :high,
      'd2.8xlarge' => :ten_gigabit,
      'd2.xlarge' => :moderate,
      'db.cr1.8xlarge' => :ten_gigabit,
      'db.m1.large' => :moderate,
      'db.m1.medium' => :moderate,
      'db.m1.small' => :low,
      'db.m1.xlarge' => :high,
      'db.m2.2xlarge' => :moderate,
      'db.m2.4xlarge' => :high,
      'db.m2.xlarge' => :moderate,
      'db.m3.2xlarge' => :high,
      'db.m3.large' => :moderate,
      'db.m3.medium' => :moderate,
      'db.m3.xlarge' => :high,
      'db.m4.10xlarge' => :ten_gigabit,
      'db.m4.2xlarge' => :high,
      'db.m4.4xlarge' => :high,
      'db.m4.large' => :moderate,
      'db.m4.xlarge' => :high,
      'db.m4.16xlarge' => :twentyfive_gigabit,
      'db.r3.2xlarge' => :high,
      'db.r3.4xlarge' => :high,
      'db.r3.8xlarge' => :ten_gigabit,
      'db.r3.large' => :moderate,
      'db.r3.xlarge' => :moderate,
      'db.r4.large' => :ten_gigabit,
      'db.r4.xlarge' => :ten_gigabit,
      'db.r4.2xlarge' => :ten_gigabit,
      'db.r4.4xlarge' => :ten_gigabit,
      'db.r4.8xlarge' => :ten_gigabit,
      'db.r4.16xlarge' => :twentyfive_gigabit,
      'db.t1.micro' => :very_low,
      'db.t2.large' => :low_to_moderate,
      'db.t2.medium' => :low_to_moderate,
      'db.t2.micro' => :low,
      'db.t2.small' => :low_to_moderate,
      'db.t2.xlarge' => :moderate,
      'db.t2.2xlarge' => :moderate,
      'db.x1.16xlarge' => :ten_gigabit,
      'db.x1.32xlarge' => :ten_gigabit,
      'f1.2xlarge' => :high,
      'f1.4xlarge' => :high,
      'f1.16xlarge' => :twentyfive_gigabit,
      'g2.2xlarge' => :high,
      'g2.8xlarge' => :ten_gigabit,
      'g3.4xlarge' => :twenty_gigabit,
      'g3.8xlarge' => :twenty_gigabit,
      'g3.16xlarge' => :twenty_gigabit,
      'g3s.xlarge' => :ten_gigabit,
      'h1.2xlarge' => :ten_gigabit, # upto 10G
      'h1.4xlarge' => :ten_gigabit, # upto 10G
      'h1.8xlarge' => :ten_gigabit,
      'h1.16xlarge' => :twentyfive_gigabit,
      'hi1.4xlarge' => :ten_gigabit,
      'hs1.8xlarge' => :ten_gigabit,
      'i2.2xlarge' => :high,
      'i2.4xlarge' => :high,
      'i2.8xlarge' => :ten_gigabit,
      'i2.xlarge' => :moderate,
      'i3.16xlarge' => :twentyfive_gigabit,
      'i3.2xlarge' => :ten_gigabit,
      'i3.4xlarge' => :ten_gigabit,
      'i3.8xlarge' => :ten_gigabit,
      'i3.large' => :ten_gigabit,
      'i3.metal' => :twentyfive_gigabit,
      'i3p.16xlarge' => :twentyfive_gigabit,
      'i3.xlarge' => :ten_gigabit,
      'm1.large' => :moderate,
      'm1.medium' => :moderate,
      'm1.small' => :low,
      'm1.xlarge' => :high,
      'm2.2xlarge' => :moderate,
      'm2.4xlarge' => :high,
      'm2.xlarge' => :moderate,
      'm3.2xlarge' => :high,
      'm3.large' => :moderate,
      'm3.medium' => :moderate,
      'm3.xlarge' => :high,
      'm4.16xlarge' => :twentyfive_gigabit,
      'm4.10xlarge' => :ten_gigabit,
      'm4.2xlarge' => :high,
      'm4.4xlarge' => :high,
      'm4.large' => :moderate,
      'm4.xlarge' => :high,
      'm5.large' => :ten_gigabit,   # upto 10G
      'm5.xlarge' => :ten_gigabit,  # upto 10G
      'm5.2xlarge' => :ten_gigabit, # upto 10G
      'm5.4xlarge' => :ten_gigabit, # upto 10G
      'm5.12xlarge' => :ten_gigabit,
      'm5.24xlarge' => :ten_gigabit,
      'm5.metal' => :twentyfive_gigabit,
      'm5d.large' => :ten_gigabit,   # upto 10G
      'm5d.xlarge' => :ten_gigabit,  # upto 10G
      'm5d.2xlarge' => :ten_gigabit, # upto 10G
      'm5d.4xlarge' => :ten_gigabit, # upto 10G
      'm5d.12xlarge' => :ten_gigabit,
      'm5d.24xlarge' => :twentyfive_gigabit,
      'm5d.metal' => :twentyfive_gigabit,
      'p2.xlarge' =>   :high,
      'p2.8xlarge' =>  :ten_gigabit,
      'p2.16xlarge' => :twenty_gigabit,
      'p3.2xlarge' =>   :high,
      'p3.8xlarge' =>  :ten_gigabit,
      'p3.16xlarge' => :twentyfive_gigabit,
      'p3dn.24xlarge' => :one_hundred_gigabit,
      'r3.2xlarge' => :high,
      'r3.4xlarge' => :high,
      'r3.8xlarge' => :ten_gigabit,
      'r3.large' => :moderate,
      'r3.xlarge' => :moderate,
      'r4.16xlarge' => :twentyfive_gigabit,
      'r4.2xlarge' => :ten_gigabit,
      'r4.4xlarge' => :ten_gigabit,
      'r4.8xlarge' => :ten_gigabit,
      'r4.large' => :ten_gigabit,
      'r4.xlarge' => :ten_gigabit,
      'r5.large' => :ten_gigabit, # upto 10G
      'r5.xlarge' => :ten_gigabit, # upto 10G
      'r5.2xlarge' => :ten_gigabit, # upto 10G
      'r5.4xlarge' => :ten_gigabit, # upto 10G
      'r5.12xlarge' => :ten_gigabit,
      'r5.24xlarge' => :twentyfive_gigabit,
      'r5.metal' => :twentyfive_gigabit,
      'r5d.large' => :ten_gigabit, # upto 10G
      'r5d.xlarge' => :ten_gigabit, # upto 10G
      'r5d.2xlarge' => :ten_gigabit, # upto 10G
      'r5d.4xlarge' => :ten_gigabit, # upto 10G
      'r5d.12xlarge' => :ten_gigabit,
      'r5d.24xlarge' => :twentyfive_gigabit,
      'r5d.metal' => :twentyfive_gigabit,
      't1.micro' => :very_low,
      't2.large' => :low_to_moderate,
      't2.medium' => :low_to_moderate,
      't2.micro' => :low_to_moderate,
      't2.nano' => :low,
      't2.small' => :low_to_moderate,
      't2.xlarge' => :high,   # same as c4.2xlarge, cf:https://aws.amazon.com/blogs/aws/new-t2-xlarge-and-t2-2xlarge-instances/
      't2.2xlarge' => :high,  # same as m4.xlarge,  cf:https://aws.amazon.com/blogs/aws/new-t2-xlarge-and-t2-2xlarge-instances/
      't3.nano' => :low,
      't3.micro' => :low_to_moderate,
      't3.small' => :low_to_moderate,
      't3.medium' => :low_to_moderate,
      't3.large' => :low_to_moderate,
      't3.xlarge' => :moderate,
      't3.2xlarge' => :moderate,
      'x1.16xlarge' => :ten_gigabit,
      'x1.32xlarge' => :twenty_gigabit,
      'x1e.16xlarge' => :ten_gigabit,
      'x1e.2xlarge' => :ten_gigabit,        # upto 10G
      'x1e.32xlarge' => :twentyfive_gigabit,
      'x1e.4xlarge' => :ten_gigabit,        # upto 10G
      'x1e.8xlarge' => :ten_gigabit,        # upto 10G
      'x1e.xlarge' => :ten_gigabit,         # upto 10G
      'z1d.large' => :ten_gigabit, # upto 10G
      'z1d.xlarge' => :ten_gigabit, # upto 10G
      'z1d.2xlarge' => :ten_gigabit, # upto 10G
      'z1d.3xlarge' => :ten_gigabit, # upto 10G
      'z1d.6xlarge' => :ten_gigabit,
      'z1d.12xlarge' => :twentyfive_gigabit,
      'z1d.metal' => :twentyfive_gigabit,
      'm5a.large' => :ten_gigabit, # upto 10G
      'm5a.xlarge' => :ten_gigabit, # upto 10G
      'm5a.2xlarge' => :ten_gigabit, # upto 10G
      'm5a.4xlarge' => :ten_gigabit, # upto 10G
      'm5a.12xlarge' => :ten_gigabit,
      'm5a.24xlarge' => :twenty_gigabit,
      'r5a.large' => :ten_gigabit, # upto 10G
      'r5a.xlarge' => :ten_gigabit, # upto 10G
      'r5a.2xlarge' => :ten_gigabit, # upto 10G
      'r5a.4xlarge' => :ten_gigabit, # upto 10G
      'r5a.12xlarge' => :ten_gigabit,
      'r5a.24xlarge' => :twenty_gigabit,
      'u-6tb1.metal' =>  :twentyfive_gigabit,
      'u-9tb1.metal' =>  :twentyfive_gigabit,
      'u-12tb1.metal' => :twentyfive_gigabit,

    }

  end

end
