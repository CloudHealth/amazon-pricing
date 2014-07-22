module AwsPricing
  class Ec2PriceList < PriceList
    
    def initialize
      @_regions = {}
      InstanceType.populate_lookups
      get_ec2_on_demand_instance_pricing
      get_ec2_reserved_instance_pricing
      fetch_ec2_ebs_pricing
    end

    protected

    @@OS_TYPES = [:linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb]
    @@RES_TYPES = [:light, :medium, :heavy]

    def get_ec2_on_demand_instance_pricing
      @@OS_TYPES.each do |os|
        fetch_ec2_instance_pricing(EC2_BASE_URL + "#{os}-od.min.js", :ondemand, os)
      end
      # Rinse & repeat for legacy instances
      @@OS_TYPES.each do |os|
        fetch_ec2_instance_pricing(EC2_BASE_URL + "previous-generation/#{os}-od.min.js", :ondemand, os)
      end
    end

    def get_ec2_reserved_instance_pricing
      @@OS_TYPES.each do |os|
        @@RES_TYPES.each do |res_type|
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

    # Retrieves the EC2 on-demand instance pricing.
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def fetch_ec2_instance_pricing(url, type_of_instance, operating_system)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
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
