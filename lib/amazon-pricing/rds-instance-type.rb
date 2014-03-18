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

      @disk_in_gb = @@Disk_Lookup[api_name_for_lookup]
      @platform = @@Platform_Lookup[api_name_for_lookup]
      @disk_type = @@Disk_Type_Lookup[api_name_for_lookup]
      # The pricing API does NOT provide these for RDS (!) - so still need our hard-coded lookups
      # e.g. http://aws-assets-pricing-prod.s3.amazonaws.com/pricing/rds/mysql/pricing-standard-deployments.js
      @memory_in_mb = @@Memory_Lookup[api_name_for_lookup]
      @compute_units = @@Compute_Units_Lookup[api_name_for_lookup]
      @virtual_cores = @@Virtual_Cores_Lookup[api_name_for_lookup]
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

    # These hard-coded lookups will go away when AWS pricing API supports providing this for RDS instance types
    # e.g. http://aws-assets-pricing-prod.s3.amazonaws.com/pricing/rds/mysql/pricing-standard-deployments.js
    @@Memory_Lookup = {
      'm1.small' => 1700, 'm1.medium' => 3750, 'm1.large' => 7500, 'm1.xlarge' => 15000,
      'm2.xlarge' => 17100, 'm2.2xlarge' => 34200, 'm2.4xlarge' => 68400,
      'm3.medium' => 3750, 'm3.large' => 7500, 'm3.xlarge' => 15000, 'm3.2xlarge' => 30000,
      'c1.medium' => 1700, 'c1.xlarge' => 7000,
      'hi1.4xlarge' => 60500,
      'cg1.4xlarge' => 22000,
      'cc1.4xlarge' => 23000, 'cc2.8xlarge' => 60500,
      't1.micro' => 1700,
      'cr1.8xlarge' => 244000,
      'hs1.8xlarge' => 117000,
      'g2.2xlarge' => 15000,      
      'db.m1.small' => 1700, 'db.m1.medium' => 3750, 'db.m1.large' => 7500, 'db.m1.xlarge' => 15000,
      'db.m2.xlarge' => 17100, 'db.m2.2xlarge' => 34000, 'db.m2.4xlarge' => 68000, 'db.cr1.8xlarge' => 244000,
      'db.t1.micro' => 613,
      'c3.large' => 3750, 'c3.xlarge' => 7000, 'c3.2xlarge' => 15000, 'c3.4xlarge' => 30000, 'c3.8xlarge' => 60000, 
      'i2.large' => 15000, 'i2.xlarge' => 30500, 'i2.2xlarge' => 61000, 'i2.4xlarge' => 122000, 'i2.8xlarge' => 244000,
    }
    @@Compute_Units_Lookup = {
      'm1.small' => 1, 'm1.medium' => 2, 'm1.large' => 4, 'm1.xlarge' => 8,
      'm2.xlarge' => 6.5, 'm2.2xlarge' => 13, 'm2.4xlarge' => 26,
      'm3.medium' => 3, 'm3.large' => 6.5, 'm3.xlarge' => 13, 'm3.2xlarge' => 26,
      'c1.medium' => 5, 'c1.xlarge' => 20,
      'hi1.4xlarge' => 35,
      'cg1.4xlarge' => 34,
      'cc1.4xlarge' => 34, 'cc2.8xlarge' => 88,
      't1.micro' => 2,
      'cr1.8xlarge' => 88,
      'hs1.8xlarge' => 35,
      'g2.2xlarge' => 26,
      'unknown' => 0,      
      'db.m1.small' => 1, 'db.m1.medium' => 2, 'db.m1.large' => 4, 'db.m1.xlarge' => 8,
      'db.m2.xlarge' => 6.5, 'db.m2.2xlarge' => 13, 'db.m2.4xlarge' => 26, 'db.cr1.8xlarge' => 88,
      'db.t1.micro' => 1,
      'c3.large' => 7, 'c3.xlarge' => 14, 'c3.2xlarge' => 28, 'c3.4xlarge' => 55, 'c3.8xlarge' => 108, 
      # Since I2 is not released, the cpmpute units are not yet published, so this is estimate
      'i2.large' => 6.5, 'i2.xlarge' => 13, 'i2.2xlarge' => 26, 'i2.4xlarge' => 52, 'i2.8xlarge' => 104,
    }
    @@Virtual_Cores_Lookup = {
      'm1.small' => 1, 'm1.medium' => 1, 'm1.large' => 2, 'm1.xlarge' => 4,
      'm2.xlarge' => 2, 'm2.2xlarge' => 4, 'm2.4xlarge' => 8,
      'm3.medium' => 1, 'm3.large' => 2, 'm3.xlarge' => 4, 'm3.2xlarge' => 8,
      'c1.medium' => 2, 'c1.xlarge' => 8,
      'hi1.4xlarge' => 16,
      'cg1.4xlarge' => 8,
      'cc1.4xlarge' => 8, 'cc2.8xlarge' => 16,
      't1.micro' => 0,
      'cr1.8xlarge' => 32,
      'hs1.8xlarge' => 16,
      'g2.2xlarge' => 8,
      'unknown' => 0,      
      'db.m1.small' => 1, 'db.m1.medium' => 1, 'db.m1.large' => 2, 'db.m1.xlarge' => 4,
      'db.m2.xlarge' => 2, 'db.m2.2xlarge' => 4, 'db.m2.4xlarge' => 8, 'db.cr1.8xlarge' => 16,
      'db.t1.micro' => 0,
      'c3.large' => 2, 'c3.xlarge' => 4, 'c3.2xlarge' => 8, 'c3.4xlarge' => 16, 'c3.8xlarge' => 32, 
      'i2.large' => 2, 'i2.xlarge' => 4, 'i2.2xlarge' => 8, 'i2.4xlarge' => 16, 'i2.8xlarge' => 32,
    }

   end

end
