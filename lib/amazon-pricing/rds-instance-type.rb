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

  class UnknownTypeError < NameError
  end

  # RdsInstanceType is a specific type of instance in a region with a defined
  # price per hour. The price will vary by platform (Linux, Windows).
  #
  class RdsInstanceType
    attr_accessor :name, :api_name, :memory_in_mb, :disk_in_mb, :platform, :compute_units, :virtual_cores

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
    # database_type = :mysql, :oracle, :sqlserver
    # type_of_rds_instance = :ondemand, :light, :medium, :heavy
    def available?(type_of_rds_instance = :ondemand, database_type = :linux)
      db = get_database_type(database_type)
      return false if db.nil?
      db.available?(type_of_rds_instance)
    end

    # type_of_rds_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def price_per_hour(database_type, type_of_rds_instance, term = nil)
      db = get_database_type(database_type)
      db.price_per_hour(type_of_rds_instance, term)
    end

    # type_of_rds_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def prepay(database_type, type_of_rds_instance, term = nil)
      db = get_database_type(database_type)
      db.prepay(type_of_rds_instance, term)
    end

    # database_type = :mysql, :oracle, :sqlserver
    # type_of_rds_instance = :ondemand, :light, :medium, :heavy
    def update_pricing(database_type, type_of_rds_instance, json)
      db = get_database_type(database_type)
      if db.nil?
        db = DatabaseType.new(self, database_type)
        @database_types[database_type] = db
      end

      if type_of_rds_instance == :ondemand
        values = RdsInstanceType::get_values(json,database_type)
        price = coerce_price(values[database_type.to_sym])
        db.set_price_per_hour(type_of_rds_instance, nil, price)
      else
        json['valueColumns'].each do |val|
          price = coerce_price(val['prices']['USD'])
          case val["name"]
          when "yrTerm1"
            db.set_prepay(type_of_rds_instance, :year1, price)
          when "yrTerm3"
            db.set_prepay(type_of_rds_instance, :year3, price)
          when "yrTerm1Hourly"
            db.set_price_per_hour(type_of_rds_instance, :year1, price)
          when "yrTerm3Hourly"
            db.set_price_per_hour(type_of_rds_instance, :year3, price)
          end
        end
      end
    end

    # type_of_rds_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def get_breakeven_month(database_type, type_of_rds_instance, term)
      db = get_database_type(database_type)
      db.get_breakeven_month(type_of_rds_instance, term)
    end

    protected

    def coerce_price(price)
      return nil if price.nil? || price == "N/A"
      price.to_f
    end

    # Returns [api_name, name]
    def self.get_name(instance_type, size, is_reserved = false)
      lookup = @@Api_Name_Lookup
      lookup = @@Api_Name_Lookup_Reserved if is_reserved

      # Let's handle new instances more gracefully
      unless lookup.has_key? instance_type
        raise UnknownTypeError, "Unknown instance type #{instance_type}", caller
      else
        api_name = lookup[instance_type][size]
      end

      lookup = @@Name_Lookup
      lookup = @@Name_Lookup_Reserved if is_reserved
      name = lookup[instance_type][size]

      [api_name, name]
    end

    # Turn json into hash table for parsing
    def self.get_values(json,database_type)
      #json: {"prices"=>{"USD"=>"4.345"}, "name"=>"xxxxDBInst"}
      values = {}
        values[database_type] = json['prices']['USD']
      values
    end

    @@Api_Name_Lookup = {
      
      'udbInstClass' => {'uDBInst'=>'t1.micro'},
      'dbInstClass'=> {'uDBInst' => 't1.micro', 'smDBInst' => 'm1.small', 'medDBInst' => 'm1.medium', 'lgDBInst' => 'm1.large', 'xlDBInst' => 'm1.xlarge'},
      'hiMemDBInstClass'=> {'xlDBInst' => 'm2.xlarge', 'xxlDBInst' => 'm2.2xlarge', 'xxxxDBInst' => 'm2.4xlarge'},
      'clusterHiMemDB' => {'xxxxxxxxl' => 'm2.8xlarge'},

      'multiAZDBInstClass'=> {'uDBInst' => 't1.micro', 'smDBInst' => 'm1.small', 'medDBInst' => 'm1.medium', 'lgDBInst' => 'm1.large', 'xlDBInst' => 'm1.xlarge'},
      'multiAZHiMemInstClass'=> {'xlDBInst' => 'm2.xlarge', 'xxlDBInst' => 'm2.2xlarge', 'xxxxDBInst' => 'm2.4xlarge'}
    
    }

    @@Name_Lookup = {
      'udbInstClass' => {'uDBInst'=>'Standard Micro'},
      'dbInstClass'=> {'uDBInst' => 'Standard Micro', 'smDBInst' => 'Standard Small', 'medDBInst' => 'Standard Medium', 'lgDBInst' => 'Standard Large', 'xlDBInst' => 'Standard Extra Large'},
      'hiMemDBInstClass'=> {'xlDBInst' => 'Standard High-Memory Extra Large', 'xxlDBInst' => 'Standard High-Memory Double Extra Large', 'xxxxDBInst' => 'Standard High-Memory Quadruple Extra Large'},
      'clusterHiMemDB' => {'xxxxxxxxl' => 'Standard High-Memory Cluster Eight Extra Large'},

      'multiAZDBInstClass'=> {'uDBInst' => 'Multi-AZ Micro', 'smDBInst' => 'Multi-AZ Small', 'medDBInst' => 'Multi-AZ Medium', 'lgDBInst' => 'Multi-AZ Large', 'xlDBInst' => 'Multi-AZ Extra Large'},
      'multiAZHiMemInstClass'=> {'xlDBInst' => 'Multi-AZ High-Memory Extra Large', 'xxlDBInst' => 'Multi-AZ High-Memory Double Extra Large', 'xxxxDBInst' => 'Multi-AZ High-Memory Quadruple Extra Large'}
    }

    @@Api_Name_Lookup_Reserved = {
      'stdDeployRes' => {'u' => 't1.micro', 'micro' => 't1.micro', 'sm' => 'm1.small', 'med' => 'm1.medium', 'lg' => 'm1.large', 'xl' => 'm1.xlarge', 'xlHiMem' => 'm2.xlarge', 'xxlHiMem' => 'm2.2xlarge', 'xxxxlHiMem' => 'm2.4xlarge'}  ,
      'multiAZdeployRes' => {'u' => 't1.micro', 'micro' => 't1.micro', 'sm' => 'm1.small', 'med' => 'm1.medium', 'lg' => 'm1.large', 'xl' => 'm1.xlarge', 'xlHiMem' => 'm2.xlarge', 'xxlHiMem' => 'm2.2xlarge', 'xxxxlHiMem' => 'm2.4xlarge'}  
    }

    @@Name_Lookup_Reserved = {
      'stdDeployRes' => {'u' => 'Standard Micro', 'micro' => 'Standard Micro', 'sm' => 'Standard Small', 'med' => 'Standard Medium', 'lg' => 'Standard Large', 'xl' => 'Standard Extra Large', 'xlHiMem' => 'Standard Extra Large High-Memory', 'xxlHiMem' => 'Standard Double Extra Large High-Memory', 'xxxxlHiMem' => 'Standard Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Standard Eight Extra Large'}  ,
      'multiAZdeployRes' => {'u' => 'Multi-AZ Micro', 'micro' => 'Multi-AZ Micro', 'sm' => 'Multi-AZ Small', 'med' => 'Multi-AZ Medium', 'lg' => 'Multi-AZ Large', 'xl' => 'Multi-AZ Extra Large', 'xlHiMem' => 'Multi-AZ Extra Large High-Memory', 'xxlHiMem' => 'Multi-AZ Double Extra Large High-Memory', 'xxxxlHiMem' => 'Multi-AZ Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Multi-AZ Eight Extra Large'}  
    }

    @@Memory_Lookup = {
      'm1.small' => 1700, 'm1.medium' => 3750, 'm1.large' => 7500, 'm1.xlarge' => 15000,
      'm2.xlarge' => 17100, 'm2.2xlarge' => 34200, 'm2.4xlarge' => 68400, 'm2.8xlarge' => 136800,
      'm3.xlarge' => 15000, 'm3.2xlarge' => 30000,
      'c1.medium' => 1700, 'c1.xlarge' => 7000,
      'hi1.4xlarge' => 60500,
      'cg1.4xlarge' => 22000,
      'cc1.4xlarge' => 23000, 'cc2.8xlarge' => 60500,
      't1.micro' => 1700,
      'm3.xlarge' => 15000, 'm3.xlarge' => 30000,
      'cr1.8xlarge' => 244000,
      'hs1.8xlarge' => 117000,
    }
    @@Disk_Lookup = {
      'm1.small' => 160, 'm1.medium' => 410, 'm1.large' =>850, 'm1.xlarge' => 1690,
      'm2.xlarge' => 420, 'm2.2xlarge' => 850, 'm2.4xlarge' => 1690, 'm2.8xlarge' => 000,
      'm3.xlarge' => 0, 'm3.2xlarge' => 0,
      'c1.medium' => 350, 'c1.xlarge' => 1690,
      'hi1.4xlarge' => 2048,
      'cg1.4xlarge' => 1690,
      'cc1.4xlarge' => 1690, 'cc2.8xlarge' => 3370,
      't1.micro' => 160,
      'm3.xlarge' => 0, 'm3.xlarge' => 0,
      'cr1.8xlarge' => 240,
      'hs1.8xlarge' => 48000,
    }
    @@Platform_Lookup = {
      'm1.small' => 32, 'm1.medium' => 32, 'm1.large' => 64, 'm1.xlarge' => 64,
      'm2.xlarge' => 64, 'm2.2xlarge' => 64, 'm2.4xlarge' => 64, 'm2.8xlarge' => 64,
      'm3.xlarge' => 64, 'm3.2xlarge' => 64,
      'c1.medium' => 32, 'c1.xlarge' => 64,
      'hi1.4xlarge' => 64,
      'cg1.4xlarge' => 64,
      'cc1.4xlarge' => 64, 'cc2.8xlarge' => 64,
      't1.micro' => 32,
      'm3.xlarge' => 64, 'm3.xlarge' => 64,
      'cr1.8xlarge' => 64,
      'hs1.8xlarge' => 64,
    }
    @@Compute_Units_Lookup = {
      'm1.small' => 1, 'm1.medium' => 2, 'm1.large' => 4, 'm1.xlarge' => 8,
      'm2.xlarge' => 6, 'm2.2xlarge' => 13, 'm2.4xlarge' => 26, 'm2.8xlarge' => 52,
      'm3.xlarge' => 13, 'm3.2xlarge' => 26,
      'c1.medium' => 5, 'c1.xlarge' => 20,
      'hi1.4xlarge' => 35,
      'cg1.4xlarge' => 34,
      'cc1.4xlarge' => 34, 'cc2.8xlarge' => 88,
      't1.micro' => 2,
      'cr1.8xlarge' => 88,
      'hs1.8xlarge' => 35,
      'unknown' => 0,
    }
    @@Virtual_Cores_Lookup = {
      'm1.small' => 1, 'm1.medium' => 1, 'm1.large' => 2, 'm1.xlarge' => 4,
      'm2.xlarge' => 2, 'm2.2xlarge' => 4, 'm2.4xlarge' => 8, 'm2.8xlarge' => 16,
      'm3.xlarge' => 4, 'm3.2xlarge' => 8,
      'c1.medium' => 2, 'c1.xlarge' => 8,
      'hi1.4xlarge' => 16,
      'cg1.4xlarge' => 8,
      'cc1.4xlarge' => 8, 'cc2.8xlarge' => 16,
      't1.micro' => 0,
      'cr1.8xlarge' => 16,
      'hs1.8xlarge' => 16,
      'unknown' => 0,
    }
  end
end
