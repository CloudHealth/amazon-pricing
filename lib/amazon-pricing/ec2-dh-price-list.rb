module AwsPricing
  class Ec2DedicatedHostPriceList < PriceList
    include AwsPricing::Ec2Common

    def initialize
      super
      InstanceType.populate_lookups
      get_ec2_dh_od_pricing
    end

    def os_types
      @@OS_TYPES
    end

    protected

    @@OS_TYPES = [ 'linux', 'rhel', 'sles', 'mswin', 'mswinSQL', 'mswinSQLWeb', 'mswinSQLEnterprise' ]

    def get_ec2_dh_od_pricing
      @@OS_TYPES.each do |os|
        fetch_ec2_dedicated_host_pricing(DH_OD_BASE_URL + "dh-od.min.js", os.to_sym)
      end
    end

    def fetch_ec2_dedicated_host_pricing(url, operating_system)
      res = PriceList.fetch_url(url)
      begin
        res['config']['regions'].each do |reg|
          region_name = reg['region']
          region = get_region(region_name)
          if region.nil?
            $stderr.puts "[fetch_ec2_dedicated_host_pricing] WARNING: unable to find region #{region_name}"
            next
          end
          reg['types'].each do |type|
            type_name = type['name']
            tiers = type['tiers']
            next if tiers.nil?
            tiers.each do |tier|
                family = tier['name']
                api_name = family
                dhprice = tier['prices']['USD']
                dh_type = region.add_or_update_ec2_dh_type(family)
                dh_type.update_dh_pricing(operating_system, dhprice)
            end
          end
        end
      rescue UnknownTypeError
        $stderr.puts "[fetch_ec2_dedicated_host_pricing] WARNING: encountered #{$!.message}"
      end
    end
  end
end
