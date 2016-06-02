module AwsPricing
  class Ec2DiPriceList < PriceList
    include AwsPricing::Ec2Common

    def initialize
      super
      InstanceType.populate_lookups
      get_ec2_di_od_pricing
      # assumption is above/di_od populates all InstanceType's, but it missing entries e.g. x1.32xlarge;
      # the fix is we now allow fetch_ec2_instance_pricing_ri_v2 to add instance_types
      get_ec2_reserved_di_pricing
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

    def for_each_os_and_name os_index, os_name_index
      @@OS_TYPES.inject({}) {|h,o| h[o[os_index]]=o[os_name_index];h}.each do |os, os_name|
        yield os, os_name
      end
    end
  end
end
