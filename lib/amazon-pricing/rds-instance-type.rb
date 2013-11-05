require 'lib/amazon-pricing/instance-type'
module AwsPricing
  class RdsInstanceType < InstanceType
    
    def initialize(region, api_name, name)
      @database_types = {}

      @region = region
      @name = name
      @api_name = api_name

      @memory_in_mb = @@Memory_Lookup[@api_name]
      @disk_in_mb = @@Disk_Lookup[@api_name]
      @platform = @@Platform_Lookup[@api_name]
      @compute_units = @@Compute_Units_Lookup[@api_name]
      @virtual_cores = @@Virtual_Cores_Lookup[@api_name]
    end

    def database_types
      @database_types.values
    end

    def get_database_type(name)
      @database_types[name]
    end

    # Returns whether an instance_type is available. 
    # database_type = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def available?(type_of_instance = :ondemand, database_type = :linux)
      db = get_database_type(database_type)
      return false if db.nil?
      db.available?(type_of_instance)
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def price_per_hour(database_type, type_of_instance, term = nil, isMultiAz)
      db = get_database_type(database_type)
      db.price_per_hour(type_of_instance, term, isMultiAz) unless db.nil?
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def prepay(database_type, type_of_instance, term = nil, isMultiAz)
      db = get_database_type(database_type)
      db.prepay(type_of_instance, term, isMultiAz) unless db.nil?
    end

    # database_type = :linux, :mysql, :oracle, :sqlserver
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def update_pricing(database_type, type_of_instance, json, isMultiAz)
      db = get_database_type(database_type)
      if db.nil?
        db = DatabaseType.new(self, database_type)
        @database_types[database_type] = db
      end

      if type_of_instance == :ondemand
        # e.g. {"size"=>"sm", "valueColumns"=>[{"name"=>"linux", "prices"=>{"USD"=>"0.060"}}]}
        values = RdsInstanceType::get_values(json, database_type)
        price = coerce_price(values[database_type.to_s])
        db.set_price_per_hour(type_of_instance, isMultiAz, nil, price)
      else
        json['valueColumns'].each do |val|
          price = coerce_price(val['prices']['USD'])

          case val["name"]
          when "yrTerm1"
            db.set_prepay(type_of_instance, isMultiAz, :year1, price)
          when "yrTerm3"
            db.set_prepay(type_of_instance, isMultiAz, :year3, price)
          when "yrTerm1Hourly"
            db.set_price_per_hour(type_of_instance, isMultiAz, :year1, price)
          when "yrTerm3Hourly"
            db.set_price_per_hour(type_of_instance, isMultiAz, :year3, price)
          when "yearTerm1Hourly"
            db.set_price_per_hour(type_of_instance, isMultiAz, :year1, price)
          when "yearTerm3Hourly"
            db.set_price_per_hour(type_of_instance, isMultiAz, :year3, price)  
          end
        end
      end
    end


    protected 

    def self.get_values(json, category_type)
      values = {}
      unless json['valueColumns'].nil?
        json['valueColumns'].each do |val|
          values[val['name']] = val['prices']['USD']
        end
      else
        values[category_type.to_s] = json['prices']['USD']
      end
      values
    end

   end
end
