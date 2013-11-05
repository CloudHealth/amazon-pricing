require 'lib/amazon-pricing/instance-type'
module AwsPricing
  class Ec2InstanceType < InstanceType
    
    def initialize(region, api_name, name)
      @operating_systems = {}

      @region = region
      @name = name
      @api_name = api_name

      @memory_in_mb = @@Memory_Lookup[@api_name]
      @disk_in_mb = @@Disk_Lookup[@api_name]
      @platform = @@Platform_Lookup[@api_name]
      @compute_units = @@Compute_Units_Lookup[@api_name]
      @virtual_cores = @@Virtual_Cores_Lookup[@api_name]
    end

    def operating_systems
      @operating_systems.values
    end

    def get_operating_system(name)
      @operating_systems[name]
    end

    # Returns whether an instance_type is available. 
    # operating_system = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def available?(type_of_instance = :ondemand, operating_system = :linux)
      os = get_operating_system(operating_system)
      return false if os.nil?
      os.available?(type_of_instance)
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def price_per_hour(operating_system, type_of_instance, term = nil)
      os = get_operating_system(operating_system)
      os.price_per_hour(type_of_instance, term)
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def prepay(operating_system, type_of_instance, term = nil)
      os = get_operating_system(operating_system)
      os.prepay(type_of_instance, term)
    end

    # operating_system = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def update_pricing(operating_system, type_of_instance, json)
      os = get_operating_system(operating_system)
      if os.nil?
        os = OperatingSystem.new(self, operating_system)
        @operating_systems[operating_system] = os
      end

      if type_of_instance == :ondemand
        # e.g. {"size"=>"sm", "valueColumns"=>[{"name"=>"linux", "prices"=>{"USD"=>"0.060"}}]}
        values = Ec2InstanceType::get_values(json)
        price = coerce_price(values[operating_system.to_s])
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

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def get_breakeven_month(operating_system, type_of_instance, term)
      os = get_operating_system(operating_system)
      os.get_breakeven_month(type_of_instance, term)
    end

    protected 

    def self.get_values(json)
      # e.g. json = {"size"=>"xl", "valueColumns"=>[{"name"=>"mswinSQL", "prices"=>{"USD"=>"2.427"}}]}
      values = {}
      json['valueColumns'].each do |val|
        values[val['name']] = val['prices']['USD']
      end
      values
    end

   end
end
