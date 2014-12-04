module AwsPricing
  class Ec2PriceList < PriceList
    
    def initialize
      super
      InstanceType.populate_lookups
      get_ec2_on_demand_instance_pricing
      get_ec2_legacy_reserved_instance_pricing
      get_ec2_reserved_instance_pricing
      fetch_ec2_ebs_pricing
    end

    protected

    @@OS_TYPES = [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb]
    @@LEGACY_RES_TYPES = [:light, :medium, :heavy]

    def get_ec2_on_demand_instance_pricing
      @@OS_TYPES.each do |os|
        fetch_ec2_instance_pricing(EC2_BASE_URL + "#{os}-od.min.js", :ondemand, os)
      end
      # Rinse & repeat for legacy instances
      @@OS_TYPES.each do |os|
        fetch_ec2_instance_pricing(EC2_BASE_URL + "previous-generation/#{os}-od.min.js", :ondemand, os)
      end
    end

    def get_ec2_legacy_reserved_instance_pricing
      @@OS_TYPES.each do |os|
        @@LEGACY_RES_TYPES.each do |res_type|
          fetch_ec2_instance_pricing(EC2_BASE_URL + "#{os}-ri-#{res_type}.min.js", res_type, os)
          # Rinse & repeat for legacy instances (note: amazon changed URLs for legacy reserved instances)
          os_rewrite = os
          os_rewrite = "redhatlinux" if os == :rhel
          os_rewrite = "suselinux" if os == :sles
          os_rewrite = "mswinsqlstd" if os == :mswinSQL
          os_rewrite = "mswinsqlweb" if os == :mswinSQLWeb
          fetch_ec2_instance_pricing(EC2_BASE_URL + "previous-generation/#{res_type}_#{os_rewrite}.min.js", res_type, os)
        end
      end
    end

    def get_ec2_reserved_instance_pricing
      # I give up on finding a pattern so just iterating over known URLs
      page_targets = {"linux-unix" => :linux, "red-hat-enterprise-linux" => :rhel, "suse-linux" => :sles, "windows" => :mswin, "windows-with-sql-server-standard" => :mswinSQL, "windows-with-sql-server-web" => :mswinSQLWeb}
      page_targets.each_pair do |target, operating_system|
        url = "#{EC2_BASE_URL}ri-v2/#{target}-shared.min.js"
        fetch_ec2_instance_pricing_ri_v2(url, operating_system)
      end
    end

    # Retrieves the EC2 on-demand instance pricing.
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def fetch_ec2_instance_pricing(url, type_of_instance, operating_system)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = get_region(region_name)
        # e.g. type = {"type"=>"hiCPUODI", "sizes"=>[{"size"=>"med", "valueColumns"=>[{"name"=>"mswinSQL", "prices"=>{"USD"=>"N/A"}}]}, {"size"=>"xl", "valueColumns"=>[{"name"=>"mswinSQL", "prices"=>{"USD"=>"2.427"}}]}]}
        reg['instanceTypes'].each do |type|
          # e.g. size = {"size"=>"xl", "valueColumns"=>[{"name"=>"mswinSQL", "prices"=>{"USD"=>"2.427"}}]}
          # Amazon now can return array or hash here (hash = only 1 item)
          items = type['sizes']
          items = [type] if items.nil?
          items.each do |size|
            begin
              api_name, name = Ec2InstanceType.get_name(type["type"], size["size"], type_of_instance != :ondemand)
              
              instance_type = region.add_or_update_ec2_instance_type(api_name, name)
              instance_type.update_pricing(operating_system, type_of_instance, size)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    end

    # Retrieves the EC2 on-demand instance pricing.
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def fetch_ec2_instance_pricing(url, type_of_instance, operating_system)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = get_region(region_name)
        if region.nil?
          $stderr.puts "WARNING: unable to find region #{region_name}"
          next
        end
        # e.g. type = {"type"=>"hiCPUODI", "sizes"=>[{"size"=>"med", "valueColumns"=>[{"name"=>"mswinSQL", "prices"=>{"USD"=>"N/A"}}]}, {"size"=>"xl", "valueColumns"=>[{"name"=>"mswinSQL", "prices"=>{"USD"=>"2.427"}}]}]}
        reg['instanceTypes'].each do |type|
          # e.g. size = {"size"=>"xl", "valueColumns"=>[{"name"=>"mswinSQL", "prices"=>{"USD"=>"2.427"}}]}
          # Amazon now can return array or hash here (hash = only 1 item)
          items = type['sizes']
          items = [type] if items.nil?
          items.each do |size|
            begin
              api_name, name = Ec2InstanceType.get_name(type["type"], size["size"], type_of_instance != :ondemand)
              instance_type = region.add_or_update_ec2_instance_type(api_name, name)
              instance_type.update_pricing(operating_system, type_of_instance, size)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    end

    # With v2 of RIs they have an entirely new format that needs to be parsed
    def fetch_ec2_instance_pricing_ri_v2(url, operating_system)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = get_region(region_name)
        if region.nil?
          $stderr.puts "WARNING: unable to find region #{region_name}"
          next
        end
        reg['instanceTypes'].each do |type|
          api_name = type["type"]
          instance_type = region.get_instance_type(api_name)
          if instance_type.nil?
            $stderr.puts "WARNING: new reserved instances not found for #{api_name} in #{region_name}"
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
              upfront = prices.select{|i| i["name"] == "upfront"}.first
              instance_type.update_pricing_new(operating_system, reservation_type, upfront["prices"]["USD"].to_f, duration, true) unless upfront.nil?
              hourly = prices.select{|i| i["name"] == "monthlyStar"}.first
              instance_type.update_pricing_new(operating_system, reservation_type, hourly["prices"]["USD"].to_f, duration, false)
            end
          end

        end
      end
    end


    def fetch_ec2_ebs_pricing
      res = PriceList.fetch_url(EBS_BASE_URL + "pricing-ebs.min.js")
      res["config"]["regions"].each do |ebs_types|
        region = get_region(ebs_types["region"])
        region.ebs_price = EbsPrice.new(region)
        region.ebs_price.update_from_json(ebs_types)
      end
    end

  end
end
