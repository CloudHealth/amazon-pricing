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
          instance_type = ensure_existence_of_instance_type(region, region_name, api_name, operating_system, type)
          if instance_type.nil?
            $stderr.puts "[fetch_ec2_instance_pricing_ri_v2] WARNING: new reserved instances not found for #{api_name} in #{region_name} using #{url}"
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

# let's make sure instance_type for this region has been setup correctly
    def ensure_existence_of_instance_type(region, region_name, api_name, operating_system, type_json)
      # input:  region
      #         region_name
      #         api_name
      #         operating_system
      #         json: ri_v2 which describes instance_type (under region)
      instance_type = find_or_create_instance_type(region, api_name, operating_system)
      if not instance_type.nil?
        set_od_price_if_missing(region, region_name, api_name, operating_system, instance_type, type_json)
      end
      instance_type
    end

# see if instance_type is missing; normally fetch_ec2_instance_pricing() adds instance_type and od-pricing;
# but if there's AWS inconsistency, make sure we add instance_type now.
    def find_or_create_instance_type(region, api_name, operating_system)
      if not region.instance_type_available?(api_name, :ondemand, operating_system)
        begin
          api_name, name = Ec2InstanceType.get_name("",       #unused
                                                    api_name,
                                                    false)    #!:ondemand
          instance_type = region.add_or_update_ec2_instance_type(api_name, name)
        rescue UnknownTypeError
          $stderr.puts "[#{__method__}] WARNING: unknown Ec2InstanceType:#{api_name} ignored"
          instance_type = nil
        end
      elsif
        instance_type = region.get_ec2_instance_type(api_name)
      end
      instance_type
    end

# OnDemand pricing might be missing, and it's a prerequisite for it to be there for our model.
# one reason it's missing, is AWS added a new instance type, and we only find it now in ri
    def set_od_price_if_missing(region, region_name, api_name, operating_system, instance_type, type_json)
      type_json["terms"].each do |term|
        # handle case of ondemand pricing missing;  turns out od-pricing is also in ri-pricing
        # (assumes od pricing has been set, iff both api_name+os are available)
        if not region.instance_type_available?(api_name, :ondemand, operating_system)
          # nb: we actually don't each-iterate below, and ignore extraneous iterations
          term["onDemandHourly"].each do |od_option|
            # handle case of ondemand pricing missing from non-ri case, let's try populating it here
            # [{purchaseOption:"ODHourly",rate:"perhr",prices:{USD:"13.338"}}],
            if od_option["purchaseOption"] != "ODHourly" || od_option["rate"] != "perhr"
              $stderr.puts "[set_od_price_if_missing] WARNING unexpected od_option #{od_option}"
            end
            price = od_option["prices"]["USD"]
            instance_type.update_pricing_new(operating_system, :ondemand, price)
            logger.debug "od pricing update #{api_name} price #{price} for #{region_name}/#{operating_system}"
            # prevent iteration, since it doesn't make sense, noting it's (theoretically) possible
            break
          end
        end
      end
      # assert if we're still missing :ondemand, we'll eventually fail in our model
      if not region.instance_type_available?(api_name, :ondemand, operating_system)
        raise "new reserved instances missing ondemand for #{api_name} in #{region_name}/#{operating_system}}"
      end
    end

  end
end
