module AwsPricing
  module Ec2Common
    # Retrieves the EC2 on-demand instance pricing.
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def fetch_ec2_instance_pricing(url, type_of_instance, operating_system)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = get_region(region_name)
        if region.nil?
          $stderr.puts "[fetch_ec2_instance_pricing] WARNING: unable to find region #{region_name}"
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
              $stderr.puts "[fetch_ec2_instance_pricing] WARNING: encountered #{$!.message}"
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
          $stderr.puts "[fetch_ec2_instance_pricing_ri_v2] WARNING: unable to find region #{region_name}"
          next
        end
        reg['instanceTypes'].each do |type|
          api_name = type["type"]
          instance_type = region.get_instance_type(api_name)
          if instance_type.nil?
            $stderr.puts "[fetch_ec2_instance_pricing_ri_v2] WARNING: new reserved instances not found for #{api_name} in #{region_name}"
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
              price = upfront["prices"]["USD"]
              instance_type.update_pricing_new(operating_system, reservation_type, price, duration, true) unless reservation_type == :noupfront || price == "N/A"
              hourly = prices.select{|i| i["name"] == "monthlyStar"}.first
              price = hourly["prices"]["USD"]
              instance_type.update_pricing_new(operating_system, reservation_type, price, duration, false) unless reservation_type == :allupfront || price == "N/A"
            end
          end

        end
      end
    end
  end
end