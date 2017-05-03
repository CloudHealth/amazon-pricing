module AwsPricing
  class Ec2DesignatedHostInstancePriceList < PriceList
    include AwsPricing::Ec2Common

    def initialize
      super
      InstanceType.populate_lookups
      get_ec2_dhi_od_pricing
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

    @@CAPACITY_HASH = {
      'c3' => { "large"=>16, "xlarge"=>8, "2xlarge"=>4, "4xlarge"=>2, "8xlarge"=>1 },
      'c4' => { "large"=>16, "xlarge"=>8, "2xlarge"=>4, "4xlarge"=>2, "8xlarge"=>1 },
      'p2' => { "xlarge"=>16, "8xlarge"=>2, "16xlarge"=>1 },
      'g2' => { "2xlarge"=>4, "8xlarge"=>1 },
      'm3' => { "medium"=>32, "large"=>16, "xlarge"=>8, "2xlarge"=>4 },
      'd2' => { "xlarge"=>8, "2xlarge"=>4, "4xlarge"=>2, "8xlarge"=>1 },
      'r4' => { "large"=>32, "xlarge"=>16, "2xlarge"=>8, "4xlarge"=>4, "8xlarge"=>2, "16xlarge"=>1 },
      'r3' => { "large"=>16, "xlarge"=>8, "2xlarge"=>4, "4xlarge"=>2, "8xlarge"=>1 },
      'm4' => { "large"=>22, "xlarge"=>11, "2xlarge"=>5, "4xlarge"=>4, "10xlarge"=>1, "16xlarge"=>1 },
      'i2' => { "xlarge"=>8, "2xlarge"=>4, "4xlarge"=>2, "8xlarge"=>1, "16xlarge"=>1 },
      'i3' => { "large"=>32, "xlarge"=>16, "2xlarge"=>8, "4xlarge"=>4, "8xlarge"=>2, "16xlarge"=>1 },
      'x1' => { "16xlarge"=>2, "32xlarge"=>1 }
    }

    def get_ec2_dhi_od_pricing
      for_each_os_and_name(OS_INDEX, RI_OS_INDEX) do |os, os_name|
        fetch_ec2_dedicated_host_instance_pricing(DH_OD_BASE_URL + "dh-od.min.js", os.to_sym)
      end
    end

    def fetch_ec2_dedicated_host_instance_pricing(url, operating_system)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = get_region(region_name)
        if region.nil?
          $stderr.puts "[fetch_ec2_dedicated_host_instance_pricing] WARNING: unable to find region #{region_name}"
          next
        end
        reg['types'].each do |type|
          type_name = type['name']
          tiers = type['tiers']
          tiers.each do |tier|
            begin
              family = tier['name']
              dhprice = tier['prices']['USD']
              @@CAPACITY_HASH[family].each do |inst_size,capacity|
                api_name, name = Ec2InstanceType.get_name(family, "#{family}.#{inst_size}", false)
                instance_type = region.add_or_update_ec2_instance_type(api_name, name)
                instance_type.update_dhi_pricing(operating_system, dhprice, capacity)
              end
            rescue UnknownTypeError
              $stderr.puts "[fetch_ec2_dedicated_host_instance_pricing] WARNING: encountered #{$!.message}"
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
