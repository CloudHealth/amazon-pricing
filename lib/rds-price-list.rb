module AwsPricing
  class RdsPriceList < PriceList
    
    def initialize
      super
      InstanceType.populate_lookups
      get_rds_on_demand_instance_pricing
      get_rds_reserved_instance_pricing
    end

    protected

    @@DB_TYPE = [:mysql, :postgresql, :oracle, :sqlserver]
    @@RES_TYPES = [:light, :medium, :heavy]
    
    @@OD_DB_DEPLOY_TYPE = {
                           :mysql=> {:mysql=>["standard","multiAZ"]},
                           :postgresql=> {:postgresql=>["standard","multiAZ"]},
                           :oracle=> {:oracle_se1=>["li-standard","li-multiAZ","byol-standard","byol-multiAZ"], :oracle_se=>["byol-standard","byol-multiAZ"], :oracle_ee=>["byol-standard","byol-multiAZ"]},
                           :sqlserver=> {:sqlserver_ex=>["li-ex"], :sqlserver_web=>["li-web"], :sqlserver_se=>["li-se", "byol"], :sqlserver_ee=>["byol"]}
                        }


    @@RESERVED_DB_DEPLOY_TYPE = {
                           :oracle=> {:oracle_se1=>["li","byol"], :oracle_se=>["byol"], :oracle_ee=>["byol"]},
                           :sqlserver=> {:sqlserver_ex=>["li-ex"], :sqlserver_web=>["li-web"], :sqlserver_se=>["li-se","byol"], :sqlserver_ee=>["byol"]}
                          }

    
    def is_multi_az?(type)
      return true if type.upcase.match("MULTI-AZ")
      false
    end

    def is_byol?(type)
      return true if type.match("byol")
      false
    end                                  

    def get_rds_on_demand_instance_pricing
      @@DB_TYPE.each do |db|
        @@OD_DB_DEPLOY_TYPE[db].each {|db_type, db_instances|
          db_instances.each do |dp_type|
            #
            # to find out the byol type
            is_byol = is_byol? dp_type
            is_multi_az = dp_type.upcase.include?("MULTIAZ")

            if [:mysql, :postgresql, :oracle].include? db
              fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{dp_type}-deployments.min.js",:ondemand, db_type, is_byol, is_multi_az)
            elsif db == :sqlserver
              fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/sqlserver-#{dp_type}-ondemand.min.js",:ondemand, db_type, is_byol, is_multi_az)
            end

            # Now repeat for legacy instances
            if [:mysql, :postgresql, :oracle].include? db
              fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/previous-generation/pricing-#{dp_type}-deployments.min.js",:ondemand, db_type, is_byol, is_multi_az)
            elsif db == :sqlserver
              fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/previous-generation/sqlserver-#{dp_type}-ondemand.min.js",:ondemand, db_type, is_byol, is_multi_az)
            end

          end
        }
      end
    end

    def get_rds_reserved_instance_pricing
       @@DB_TYPE.each do |db|
        if [:mysql, :postgresql].include? db
          @@RES_TYPES.each do |res_type|
            if db == :postgresql and res_type == :heavy
              fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{res_type}-utilization-reserved-instances.min.js", res_type, db, false)
            elsif db == :mysql
              fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{res_type}-utilization-reserved-instances.min.js", res_type, db, false)
            end            

            # Now repeat for legacy instances
            if db == :postgresql and res_type == :heavy
              fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/previous-generation/pricing-#{res_type}-utilization-reserved-instances.min.js", res_type, db, false)
            elsif db == :mysql
              fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/previous-generation/pricing-#{res_type}-utilization-reserved-instances.min.js", res_type, db, false)
            end            
          end
        else
          @@RESERVED_DB_DEPLOY_TYPE[db].each {|db_type, db_instance|
            @@RES_TYPES.each do |res_type|
              db_instance.each do |dp_type|
                is_byol = is_byol? dp_type
                if db == :oracle
                  fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{dp_type}-#{res_type}-utilization-reserved-instances.min.js", res_type, db_type, is_byol) 
                elsif db == :sqlserver
                  fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/sqlserver-#{dp_type}-#{res_type}-ri.min.js", res_type, db_type, is_byol)
                end

                # Now repeat for legacy instances
                if db == :oracle
                  fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/previous-generation/pricing-#{dp_type}-#{res_type}-utilization-reserved-instances.min.js", res_type, db_type, is_byol) 
                elsif db == :sqlserver
                  fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/previous-generation/sqlserver-#{dp_type}-#{res_type}-ri.min.js", res_type, db_type, is_byol)
                end

              end    
            end            
          }
        end
      end
    end

    def fetch_on_demand_rds_instance_pricing(url, type_of_rds_instance, db_type, is_byol, is_multi_az = false)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = get_region(region_name)
        reg['types'].each do |type|
          type['tiers'].each do |tier|
            begin
              #
              # this is special case URL, it is oracle - multiAZ type of deployment but it doesn't have mutliAZ attributes in json.
              #if url == "http://aws.amazon.com/rds/pricing/oracle/pricing-li-multiAZ-deployments.min.js"
              #  is_multi_az = true
              #else
              #  is_multi_az = is_multi_az? type["name"]
              #end              
              api_name, name = RdsInstanceType.get_name(type["name"], tier["name"], type_of_rds_instance != :ondemand)
              
              instance_type = region.add_or_update_rds_instance_type(api_name, name)
              instance_type.update_pricing(db_type, type_of_rds_instance, tier, is_multi_az, is_byol)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end                        
      end
    end

    def fetch_reserved_rds_instance_pricing(url, type_of_rds_instance, db_type, is_byol)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = get_region(region_name)
        reg['instanceTypes'].each do |type|
          type['tiers'].each do |tier|
            begin
                is_multi_az = is_multi_az? type["type"]
                api_name, name = RdsInstanceType.get_name(type["type"], tier["size"], true)
                
                instance_type = region.add_or_update_rds_instance_type(api_name, name)
                instance_type.update_pricing(db_type, type_of_rds_instance, tier, is_multi_az, is_byol)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    end                              
  end
end
