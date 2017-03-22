module AwsPricing
  class Ec2DiPriceList < PriceList
    include AwsPricing::Ec2Common

    def initialize
      super
      InstanceType.populate_lookups
      get_ec2_di_od_pricing

      # assumption is above/di_od populates all InstanceType's, but is missing entries e.g. x1.32xlarge;
      # the fix is we now allow fetch_ec2_instance_pricing_ri_v2 to add instance_types
      get_ec2_reserved_di_pricing

      # di_od above also misses instances on dedicated hosts - see e2-dh-price-list.rb
      get_ec2_dh_od_pricing
    end

    protected

    @@OS_TYPES = [
        ['linux', 'linux-unix'],
        ['rhel', 'red-hat-enterprise-linux'],
        ['sles', 'suse-linux'],
        ['mswin', 'windows'],
        ['mswinSQL', 'windows-with-sql-server-standard'],
        ['mswinSQLWeb', 'windows-with-sql-server-web'],
        ['mswinSQLEnterprise', 'windows-with-sql-server-enterprise']
    ]

    OS_INDEX = 0
    OD_OS_INDEX = 0
    RI_OS_INDEX = 1

    def get_ec2_di_od_pricing
      for_each_os_and_name(OS_INDEX, OD_OS_INDEX) do |os, os_name|
        fetch_ec2_instance_pricing(DI_OD_BASE_URL + "di-#{os_name}-od.min.js", :ondemand, os.to_sym)
      end
    end

    def get_ec2_reserved_di_pricing
      for_each_os_and_name(OS_INDEX, RI_OS_INDEX) do |os, os_name|
        fetch_ec2_instance_pricing_ri_v2(RESERVED_DI_BASE_URL + "#{os_name}-dedicated.min.js", os.to_sym)
        next if os == 'mswinSQLEnterprise' # No SQL Enterprise for previous generation
        fetch_ec2_instance_pricing_ri_v2(RESERVED_DI_PREV_GEN_BASE_URL + "#{os_name}-dedicated.min.js", os.to_sym)
      end
    end

    UNSUPPORTED = -1

    @@CAPACITY_HASH = {
#             medium       large        xlarge       2xlarge      4xlarge      8xlarge      10xlarge     16xlarge     32xlarge             
      C3 => [ UNSUPPORTED, 16,          8,           4,           2,           1,           UNSUPPORTED, UNSUPPORTED, UNSUPPORTED ],
      C4 => [ UNSUPPORTED, 16,          8,           4,           2,           1,           UNSUPPORTED, UNSUPPORTED, UNSUPPORTED ],
      P2 => [ UNSUPPORTED, UNSUPPORTED, 16,          UNSUPPORTED, UNSUPPORTED, 2,           UNSUPPORTED, 1,           UNSUPPORTED ],
      G2 => [ UNSUPPORTED, UNSUPPORTED, UNSUPPORTED, 4,           UNSUPPORTED, 1,           UNSUPPORTED, UNSUPPORTED, UNSUPPORTED ],
      M3 => [ 32,          16,          8,           4,           UNSUPPORTED, UNSUPPORTED, UNSUPPORTED, UNSUPPORTED, UNSUPPORTED ],
      D2 => [ UNSUPPORTED, UNSUPPORTED, 8,           4,           2,           1,           UNSUPPORTED, UNSUPPORTED, UNSUPPORTED ],
      R4 => [ UNSUPPORTED, 32,          16,          8,           4,           2,           UNSUPPORTED, 1,           UNSUPPORTED ],
      R3 => [ UNSUPPORTED, 32,          16,          8,           4,           2,           UNSUPPORTED, UNSUPPORTED, UNSUPPORTED ],
      M4 => [ UNSUPPORTED, 22,          11,          5,           4,           UNSUPPORTED, 1,           1,           UNSUPPORTED ],
      I2 => [ UNSUPPORTED, UNSUPPORTED, 8,           4,           2,           1,           UNSUPPORTED, 1,           UNSUPPORTED ],
      I3 => [ UNSUPPORTED, 32,          8,           4,           2,           1,           UNSUPPORTED, 1,           UNSUPPORTED ],
      X1 => [ UNSUPPORTED, UNSUPPORTED, UNSUPPORTED, UNSUPPORTED, UNSUPPORTED, UNSUPPORTED, UNSUPPORTED, 2,           1 ],
    }

    def get_ec2_dhi_od_pricing
      for_each_os(OS_INDEX) do |os|
        fetch_ec2_dedicated_host_instance_pricing(DH_OD_BASE_URL + "dh-od.min.js", :ondemand, os.to_sym)
      end
    end

    def fetch_ec2_dedicated_host_instance_pricing(url, type_of_instance, operating_system)
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

    def for_each_os_and_name os_index, os_name_index
      @@OS_TYPES.inject({}) {|h,o| h[o[os_index]]=o[os_name_index];h}.each do |os, os_name|
        yield os, os_name
      end
    end

    def for_each_os os_index, os_name_index
      @@OS_TYPES.inject({}) {|h,o| h[o[os_index]]=o[os_name_index];h}.each do |os, os_name|
        yield os
      end
    end
  end
end
