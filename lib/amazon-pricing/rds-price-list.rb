module AwsPricing
  class RdsPriceList < PriceList

    def initialize
      super
      InstanceType.populate_lookups
      get_rds_on_demand_instance_pricing
      get_rds_reserved_instance_pricing2
      get_rds_reserved_instance_pricing
    end

    protected

    # NOTE if you add to DB_TYPE, make sure to update self.get_database_name
    # in amazon-pricing/lib/amazon-pricing/definitions/database-type.rb
    @@DB_TYPE = [:mysql, :postgresql, :oracle, :sqlserver, :aurora]
    @@RES_TYPES = [:light, :medium, :heavy]

    @@OD_DB_DEPLOY_TYPE = {
      :mysql => {:mysql=>["standard","multiAZ"]},
      :postgresql => {:postgresql=>["standard","multiAZ"]},
      :oracle => {
        :oracle_se1=>["li-standard","li-multiAZ","byol-standard","byol-multiAZ"],
        :oracle_se=>["byol-standard","byol-multiAZ"],
        :oracle_ee=>["byol-standard","byol-multiAZ"]
      },
      :sqlserver => {
        :sqlserver_ex=>["li-ex"],
        :sqlserver_web=>["li-web"],
        :sqlserver_se=>["li-se", "li-se-multiAZ", "byol", "byol-multiAZ"],
        :sqlserver_ee=>["byol", "byol-multiAZ"]
      },
      :aurora => { :aurora => ["multiAZ"] }
    }

    @@RESERVED_DB_DEPLOY_TYPE = {
      :oracle=> {:oracle_se1=>["li","byol"], :oracle_se=>["byol"], :oracle_ee=>["byol"]},
      :sqlserver=> {:sqlserver_ex=>["li-ex"], :sqlserver_web=>["li-web"], :sqlserver_se=>["li-se","byol"], :sqlserver_ee=>["byol"]}
    }

    @@RESERVED_DB_DEPLOY_TYPE2 = {
        :mysql => {:mysql=>["standard","multiAZ"]},
        :postgresql => {:postgresql=>["standard","multiAZ"]},
        :oracle => {:oracle_se1=>["license-included-standard", "license-included-multiAZ"],
                    :oracle_se=>["byol-standard", "byol-multiAZ"]},
        :sqlserver => {:sqlserver_se=>["byol-standard", "byol-multiAZ"]}
    }

    @@RESERVED_DB_WITH_SAME_PRICING2 = {
        :mysql => [:mysql],
        :postgresql => [:postgresql],
        :oracle_se1 => [:oracle_se1],
        :oracle_se => [:oracle_se, :oracle_se1, :oracle_ee],
        :sqlserver_se => [:sqlserver_se, :sqlserver_ee]
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
            dp_type = dp_type.gsub('-multiAZ', '') if db == :sqlserver

            if [:mysql, :postgresql, :oracle, :aurora].include? db
              url = RDS_BASE_URL + "#{db}/pricing-#{dp_type}-deployments.min.js"
              fetch_on_demand_rds_instance_pricing(url, :ondemand, db_type, is_byol, is_multi_az)
            elsif db == :sqlserver
              if is_multi_az
                fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/sqlserver-#{dp_type}-ondemand-maz.min.js",:ondemand, db_type, is_byol, is_multi_az)
              else
                fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/sqlserver-#{dp_type}-ondemand.min.js",:ondemand, db_type, is_byol, is_multi_az)
              end
            end

            # Now repeat for legacy instances
            if [:mysql, :postgresql, :oracle].include? db
              fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/previous-generation/pricing-#{dp_type}-deployments.min.js",:ondemand, db_type, is_byol, is_multi_az)
            elsif db == :sqlserver
              if is_multi_az
                fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/previous-generation/sqlserver-#{dp_type}-ondemand-maz.min.js",:ondemand, db_type, is_byol, is_multi_az)
              else
                fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/previous-generation/sqlserver-#{dp_type}-ondemand.min.js",:ondemand, db_type, is_byol, is_multi_az)
              end
            end

          end
        }
      end
    end

    def get_rds_reserved_instance_pricing2
      @@DB_TYPE.each do |db_name|
        # skip if there is no legacy price data
        next if db_name == :aurora
        @@RESERVED_DB_DEPLOY_TYPE2[db_name].each do |db, deploy_types|
          deploy_types.each do |deploy_type|
            is_byol = is_byol? deploy_type
            is_multi_az = deploy_type.upcase.include?("MULTIAZ")
            db_str = db == :sqlserver_se ? 'sql-server-se' : db.to_s.gsub(/_/, '-')
            dbs_with_same_pricing = @@RESERVED_DB_WITH_SAME_PRICING2[db]
            fetch_reserved_rds_instance_pricing2(RDS_BASE_URL+"reserved-instances/#{db_str}-#{deploy_type}.min.js", dbs_with_same_pricing, is_multi_az, is_byol)
          end
        end
      end
    end

    def fetch_reserved_rds_instance_pricing2(url, dbs, is_multi_az, is_byol)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = get_region(region_name)
        if region.nil?
          $stderr.puts "[fetch_reserved_rds_instance_pricing2] WARNING: unable to find region #{region_name}"
          next
        end
        reg['instanceTypes'].each do |type|
          api_name = type["type"]
          instance_type = region.get_rds_instance_type(api_name)
          if instance_type.nil?
            $stderr.puts "[fetch_reserved_rds_instance_pricing2] WARNING: new reserved instances not found for #{api_name} in #{region_name}"
            next
          end

          type["terms"].each do |term|
            term["purchaseOptions"].each do |option|
              case option["purchaseOption"]
                when "noUpfront"
                  reservation_type = :noupfront
                when "allUpfront"
                  reservation_type = :allupfront
                when "partialUpfront"
                  reservation_type = :partialupfront
              end

              duration = term["term"]
              prices = option["valueColumns"]
              dbs.each do |db|
                instance_type.update_pricing_new(db, reservation_type, prices, duration, is_multi_az, is_byol)
              end
            end
          end

        end
      end
    end

    def get_rds_reserved_instance_pricing
       @@DB_TYPE.each do |db|
        if [:mysql, :postgresql, :aurora].include? db
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
              $stderr.puts "[fetch_on_demand_rds_instance_pricing] WARNING: encountered #{$!.message}"
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
              $stderr.puts "[fetch_reserved_rds_instance_pricing] WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    rescue => ex
      $sterr.puts "Failed to fetch: #{url}"
      raise
    end
  end
end
