require 'amazon-pricing/instance-type'
module AwsPricing
  class RdsInstanceType < InstanceType
    # database_type = :mysql, :oracle, :sqlserver
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def update_pricing(database_type, type_of_instance, json, isMultiAz, is_byol)
      db = get_category_type(database_type, isMultiAz, is_byol)
      if db.nil?
        db = DatabaseType.new(self, database_type)        
        
        if isMultiAz == true and is_byol == true
          @category_types["#{database_type}_byol_multiAz"] = db
        elsif isMultiAz == true and is_byol == false
          @category_types["#{database_type}_multiAz"] = db
        elsif isMultiAz == false and is_byol == true
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

    @@Api_Name_Lookup = {
      'udbInstClass' => {'uDBInst'=>'db.t1.micro'},
      'dbInstClass'=> {'uDBInst' => 'db.t1.micro', 'smDBInst' => 'db.m1.small', 'medDBInst' => 'db.m1.medium', 'lgDBInst' => 'db.m1.large', 'xlDBInst' => 'db.m1.xlarge'},
      'hiMemDBInstClass'=> {'xlDBInst' => 'db.m2.xlarge', 'xxlDBInst' => 'db.m2.2xlarge', 'xxxxDBInst' => 'db.m2.4xlarge'},
      'clusterHiMemDB' => {'xxxxxxxxl' => 'db.m2.8xlarge'},
      'multiAZDBInstClass'=> {'uDBInst' => 'db.t1.micro', 'smDBInst' => 'db.m1.small', 'medDBInst' => 'db.m1.medium', 'lgDBInst' => 'db.m1.large', 'xlDBInst' => 'db.m1.xlarge'},
      'multiAZHiMemInstClass'=> {'xlDBInst' => 'db.m2.xlarge', 'xxlDBInst' => 'db.m2.2xlarge', 'xxxxDBInst' => 'db.m2.4xlarge'},
    }
    @@Name_Lookup = {
      'udbInstClass' => {'uDBInst'=>'Standard Micro'},
      'dbInstClass'=> {'uDBInst' => 'Standard Micro', 'smDBInst' => 'Standard Small', 'medDBInst' => 'Standard Medium', 'lgDBInst' => 'Standard Large', 'xlDBInst' => 'Standard Extra Large'},
      'hiMemDBInstClass'=> {'xlDBInst' => 'Standard High-Memory Extra Large', 'xxlDBInst' => 'Standard High-Memory Double Extra Large', 'xxxxDBInst' => 'Standard High-Memory Quadruple Extra Large'},
      'clusterHiMemDB' => {'xxxxxxxxl' => 'Standard High-Memory Cluster Eight Extra Large'},
      'multiAZDBInstClass'=> {'uDBInst' => 'Multi-AZ Micro', 'smDBInst' => 'Multi-AZ Small', 'medDBInst' => 'Multi-AZ Medium', 'lgDBInst' => 'Multi-AZ Large', 'xlDBInst' => 'Multi-AZ Extra Large'},
      'multiAZHiMemInstClass'=> {'xlDBInst' => 'Multi-AZ High-Memory Extra Large', 'xxlDBInst' => 'Multi-AZ High-Memory Double Extra Large', 'xxxxDBInst' => 'Multi-AZ High-Memory Quadruple Extra Large'},
    }
    @@Api_Name_Lookup_Reserved = {
      'stdDeployRes' => {'u' => 'db.t1.micro', 'micro' => 'db.t1.micro', 'sm' => 'db.m1.small', 'med' => 'db.m1.medium', 'lg' => 'db.m1.large', 'xl' => 'db.m1.xlarge', 'xlHiMem' => 'db.m2.xlarge', 'xxlHiMem' => 'db.m2.2xlarge', 'xxxxlHiMem' => 'db.m2.4xlarge', 'xxxxxxxxl' => 'db.m2.8xlarge'},
      'multiAZdeployRes' => {'u' => 'db.t1.micro', 'micro' => 'db.t1.micro', 'sm' => 'db.m1.small', 'med' => 'db.m1.medium', 'lg' => 'db.m1.large', 'xl' => 'db.m1.xlarge', 'xlHiMem' => 'db.m2.xlarge', 'xxlHiMem' => 'db.m2.2xlarge', 'xxxxlHiMem' => 'db.m2.4xlarge', 'xxxxxxxxl' => 'db.m2.8xlarge'},
    }
    @@Name_Lookup_Reserved = {
      'stdDeployRes' => {'u' => 'Standard Micro', 'micro' => 'Standard Micro', 'sm' => 'Standard Small', 'med' => 'Standard Medium', 'lg' => 'Standard Large', 'xl' => 'Standard Extra Large', 'xlHiMem' => 'Standard Extra Large High-Memory', 'xxlHiMem' => 'Standard Double Extra Large High-Memory', 'xxxxlHiMem' => 'Standard Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Standard Eight Extra Large'}  ,
      'multiAZdeployRes' => {'u' => 'Multi-AZ Micro', 'micro' => 'Multi-AZ Micro', 'sm' => 'Multi-AZ Small', 'med' => 'Multi-AZ Medium', 'lg' => 'Multi-AZ Large', 'xl' => 'Multi-AZ Extra Large', 'xlHiMem' => 'Multi-AZ Extra Large High-Memory', 'xxlHiMem' => 'Multi-AZ Double Extra Large High-Memory', 'xxxxlHiMem' => 'Multi-AZ Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Multi-AZ Eight Extra Large'},
    }
   end
end
