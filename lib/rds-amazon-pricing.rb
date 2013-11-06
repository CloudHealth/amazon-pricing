require "amazon-pricing"
module AwsPricing

  class RdsPriceList < PriceList
    
    def initialize
      @_regions = {}
       get_rds_on_demand_instance_pricing
       get_rds_reserved_instance_pricing
    end

    protected

    @@DB_TYPE = [:mysql, :oracle, :sqlserver]
    @@RES_TYPES = [:light, :medium, :heavy]
    
    @@OD_DB_DEPLOY_TYPE = {
                           :mysql=> {:mysql=>["standard","multiAZ"]},
                           :oracle=> {:oracle=>["li-standard","li-multiAZ"], :oracle_byol=>["byol-standard","byol-multiAZ"]},
                           :sqlserver=> {:sqlserver=>["li-se"], :sqlserver_express=>["li-ex"], :sqlserver_web=>["li-web"], :sqlserver_byol=>["byol"]}
                        }


    @@RESERVED_DB_DEPLOY_TYPE = {
                           :oracle=> {:oracle=>"li", :oracle_byol=>"byol"},
                           :sqlserver=> {:sqlserver=>"li-se", :sqlserver_express=>"li-ex", :sqlserver_web=>"li-web", :sqlserver_byol=>"byol"}
                          }

    
    def is_multi_az?(type)
      return true if type.match("multiAZ")
      false
    end                                  

    def get_rds_on_demand_instance_pricing
      @@DB_TYPE.each do |db|
        @@OD_DB_DEPLOY_TYPE[db].each {|db_type, db_instances|
          db_instances.each do |dp_type|
            if db == :mysql or db == :oracle
              fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{dp_type}-deployments.json",:ondemand, db_type)
            elsif db == :sqlserver
              fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/sqlserver-#{dp_type}-ondemand.json",:ondemand, db_type)
            end
          end
        }
      end
    end

    def get_rds_reserved_instance_pricing
       @@DB_TYPE.each do |db|
        if db == :mysql
          @@RES_TYPES.each do |res_type|
            fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{res_type}-utilization-reserved-instances.json", res_type, db)
          end
        else
          @@RESERVED_DB_DEPLOY_TYPE[db].each {|db_type, db_instance|
            @@RES_TYPES.each do |res_type|
              fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{db_instance}-#{res_type}-utilization-reserved-instances.json", res_type, db_type) if db == :oracle
              fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/sqlserver-#{db_instance}-#{res_type}-ri.json", res_type, db_type) if db == :sqlserver           
            end            
          }
        end
      end
    end

    def fetch_on_demand_rds_instance_pricing(url, type_of_rds_instance, db_type)
      res = fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['types'].each do |type|
          type['tiers'].each do |tier|
            begin
              #
              # this is special case URL, it is oracle - multiAZ type of deployment but it doesn't have mutliAZ attributes in json.
              if url == "http://aws.amazon.com/rds/pricing/oracle/pricing-li-multiAZ-deployments.json"
                isMultiAz = true
              else
                isMultiAz = is_multi_az? type["name"]
              end              
              api_name, name = InstanceType.get_name(type["name"], tier["name"], type_of_rds_instance != :ondemand)
              
              region.add_or_update_rds_instance_type(api_name, name, db_type, type_of_rds_instance, tier, isMultiAz)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    end

    def fetch_reserved_rds_instance_pricing(url, type_of_rds_instance, db_type)
      res = fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['instanceTypes'].each do |type|
          type['tiers'].each do |tier|
            begin
                isMultiAz = is_multi_az? type["type"]
                api_name, name = InstanceType.get_name(type["type"], tier["size"], true)
                
                region.add_or_update_rds_instance_type(api_name, name, db_type, type_of_rds_instance, tier, isMultiAz)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    end                              
  end
end