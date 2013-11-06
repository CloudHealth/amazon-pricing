require 'amazon-pricing/instance-type'
module AwsPricing
  class RdsInstanceType < InstanceType
    # database_type = :mysql, :oracle, :sqlserver
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def update_pricing(database_type, type_of_instance, json, isMultiAz)
      db = get_category_type(database_type, isMultiAz)
      if db.nil?
        db = DatabaseType.new(self, database_type)        
        if isMultiAz
          @category_types["#{database_type}_multiAz"] = db
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
   end
end
