require 'amazon-pricing/instance-type'
module AwsPricing
  class RdsInstanceType < InstanceType

    def initialize(region, api_name, name, json)
      @category_types = {}

      @region = region
      @name = name
      @api_name = api_name

      # Let's look up using the standard name but need to remove leading "db." to do so
      api_name_for_lookup = api_name.sub("db.", "")

      @disk_in_gb = InstanceType.get_disk(api_name_for_lookup)
      @platform = InstanceType.get_platform(api_name_for_lookup)
      @disk_type = InstanceType.get_disk_type(api_name_for_lookup)
      @memory_in_mb = InstanceType.get_memory(api_name_for_lookup)
      @compute_units = InstanceType.get_compute_units(api_name_for_lookup)
      @virtual_cores = InstanceType.get_virtual_cores(api_name_for_lookup)
    end


    # database_type = :mysql, :oracle, :sqlserver
    # type_of_instance = :ondemand, :light, :medium, :heavy

    def available?(database_type = :mysql, type_of_instance = :ondemand, is_multi_az, is_byol)
      db = get_category_type(database_type, is_multi_az, is_byol)
      return false if db.nil?
      db.available?(type_of_instance)
    end

    def update_pricing(database_type, type_of_instance, json, is_multi_az, is_byol)
      db = get_category_type(database_type, is_multi_az, is_byol)
      if db.nil?
        db = DatabaseType.new(self, database_type)        
        
        if is_multi_az == true and is_byol == true
          @category_types["#{database_type}_byol_multiaz"] = db
        elsif is_multi_az == true and is_byol == false
          @category_types["#{database_type}_multiaz"] = db
        elsif is_multi_az == false and is_byol == true
          @category_types["#{database_type}_byol"] = db
        else
          @category_types[database_type] = db
        end    

      end

      if type_of_instance == :ondemand
        values = RdsInstanceType::get_values(json, database_type)
        price = coerce_price(values[database_type.to_s])
        db.set_price_per_hour(type_of_instance, nil, price)
      else
        json['valueColumns'].each do |val|
          price = coerce_price(val['prices']['USD'])

          case val["name"]
          when "yrTerm1"
            db.set_prepay(type_of_instance, :year1, price)
          when "yrTerm3"
            db.set_prepay(type_of_instance, :year3, price)
          when "yrTerm1Hourly"
            db.set_price_per_hour(type_of_instance, :year1, price)
          when "yrTerm3Hourly"
            db.set_price_per_hour(type_of_instance, :year3, price)
          when "yearTerm1Hourly"
            db.set_price_per_hour(type_of_instance, :year1, price)
          when "yearTerm3Hourly"
            db.set_price_per_hour(type_of_instance, :year3, price)  
          end
        end
      end
    end

    protected 

    # Returns [api_name, name]
    # e.g. memDBCurrentGen, db.m3.medium
    def self.get_name(instance_type, api_name, is_reserved = false)
      # Temporary hack: Amazon has released r3 instances but pricing has api_name with asterisk (e.g. "r3.large *")
      api_name.sub!(" *", "")


      # Note: These api names are specific to RDS, not sure why Amazon has given them different API names (note: they have leading "db.")
      #'cr1.8xl' => 'High-Memory Cluster Eight Extra Large',
      #'micro' => 'Micro',
      #'sm' => 'Standard Small',
      #'xxlHiMem' => 'Hi-Memory Double Extra Large'
      if ["db.cr1.8xl", "db.micro", "db.sm", "db.xxlHiMem", "sm", "micro", "xxlHiMem"].include? api_name
        case api_name
        when "db.cr1.8xl"
          api_name = "db.cr1.8xlarge"
        when "db.xxlHiMem", "xxlHiMem"
          api_name = "db.m2.2xlarge"
        when "db.micro", "micro"
          api_name = "db.t1.micro"
        when "db.sm", "sm"
          api_name = "db.m1.small"
        end
      end

      # Let's look up using the standard name but need to remove leading "db." to do so
      api_name_for_lookup = api_name.sub("db.", "")

      # Let's handle new instances more gracefully
      unless @@Name_Lookup.has_key? api_name_for_lookup
        raise UnknownTypeError, "Unknown instance type #{instance_type} #{api_name}", caller
      end

      name = @@Name_Lookup[api_name_for_lookup]

      [api_name, name]
    end

   end

end
