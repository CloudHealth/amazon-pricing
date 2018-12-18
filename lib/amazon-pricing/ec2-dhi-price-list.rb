module AwsPricing
  class Ec2DedicatedHostInstancePriceList < PriceList
    include AwsPricing::Ec2Common

    def initialize
      super
      InstanceType.populate_lookups
      get_ec2_dhi_od_pricing
    end

    def os_types
      @@OS_TYPES
    end

    protected

    @@OS_TYPES = [ 'linux', 'rhel', 'sles', 'mswin', 
                   'mswinSQL', 'mswinSQLWeb', 'mswinSQLEnterprise',
                   'linuxSQL', 'linuxSQLWeb', 'linuxSQLEnterprise',
                 ]

    @@CAPACITY_HASH = { # number of instances a host can run, by definition largest size can only run one instance/host
      'a1' => {"medium" =>16, "large"=>8, "xlarge"=>4, "2xlarge"=>2, "4xlarge"=>1},
      'c3' => { "large"=>16, "xlarge"=>8, "2xlarge"=>4, "4xlarge"=>2, "8xlarge"=>1 },
      'c4' => { "large"=>16, "xlarge"=>8, "2xlarge"=>4, "4xlarge"=>2, "8xlarge"=>1 },
      'c5' => { "large"=>36, "xlarge"=>18, "2xlarge"=>8, "4xlarge"=>4,"9xlarge"=>2, "18xlarge"=>1 },
      'c5d' => { "large"=>36, "xlarge"=>18, "2xlarge"=>8, "4xlarge"=>4,"9xlarge"=>2, "18xlarge"=>1 },
      'c5n' => { "large"=>36, "xlarge"=>18, "2xlarge"=>8, "4xlarge"=>4, "9xlarge"=>2, "18xlarge" =>1 },
      'p2' => { "xlarge"=>16, "8xlarge"=>2, "16xlarge"=>1 },
      'p3' => { "2xlarge"=>8, "8xlarge"=>2, "16xlarge"=>1 },
      'p3dn' => { "24xlarge"=>1 },
      'g2' => { "2xlarge"=>4, "8xlarge"=>1 },
      'g3' => { "4xlarge"=>4, "8xlarge"=>2, "16xlarge"=>1 },
      'g3s' => { "xlarge" => 1},
      'f1' => { "2xlarge"=>8, "4xlarge"=>4, "16xlarge" =>1 },
      'm3' => { "medium"=>32, "large"=>16, "xlarge"=>8, "2xlarge"=>4 },
      'd2' => { "xlarge"=>8, "2xlarge"=>4, "4xlarge"=>2, "8xlarge"=>1 },
      'h1' => { "2xlarge"=>8, "4xlarge"=>4, "8xlarge"=>2, "16xlarge"=>1 },
      'r3' => { "large"=>16, "xlarge"=>8, "2xlarge"=>4, "4xlarge"=>2, "8xlarge"=>1 },
      'r4' => { "large"=>32, "xlarge"=>16, "2xlarge"=>8, "4xlarge"=>4, "8xlarge"=>2, "16xlarge"=>1 },
      'r5' => { "large"=>36, "xlarge"=>24, "2xlarge"=>12, "4xlarge"=>6, "12xlarge"=>2, "24xlarge"=>1 },
      'r5d' => { "large"=>36, "xlarge"=>24, "2xlarge"=>12, "4xlarge"=>6, "12xlarge"=>2, "24xlarge"=>1 },
      'm4' => { "large"=>22, "xlarge"=>11, "2xlarge"=>5, "4xlarge"=>4, "10xlarge"=>1, "16xlarge"=>1 },
      'm5' => { "large"=>48, "xlarge"=>24, "2xlarge"=>12, "4xlarge"=>6, "12xlarge"=>2, "24xlarge"=>1 },
      'm5d' => { "large"=>48, "xlarge"=>24, "2xlarge"=>12, "4xlarge"=>6, "12xlarge"=>2, "24xlarge"=>1 },
      'i2' => { "xlarge"=>8, "2xlarge"=>4, "4xlarge"=>2, "8xlarge"=>1, "16xlarge"=>1 },
      'i3' => { "large"=>32, "xlarge"=>16, "2xlarge"=>8, "4xlarge"=>4, "8xlarge"=>2, "16xlarge"=>1, "metal"=>1},
      'i3p' => {"16xlarge"=>1},
      'x1' => { "16xlarge"=>2, "32xlarge"=>1 },
      'x1e' =>{ "xlarge"=>32, "2xlarge"=>16, "4xlarge"=>8, "8xlarge"=>4, "16xlarge"=>2, "32xlarge"=>1 },
      'z1d' => {"large"=> 24, "xlarge"=> 12,  "2xlarge"=> 6,  "3xlarge"=> 4,  "6xlarge"=> 2,  "12xlarge"=> 1},

    }

    def get_ec2_dhi_od_pricing
      @@OS_TYPES.each do |os|
        fetch_ec2_dedicated_host_instance_pricing(DH_OD_BASE_URL + "dh-od.min.js", os.to_sym)
      end
    end

    def fetch_ec2_dedicated_host_instance_pricing(url, operating_system)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        begin
          region_name = reg['region']
          region = get_region(region_name)
          if region.nil?
            $stderr.puts "[fetch_ec2_dedicated_host_instance_pricing] WARNING: unable to find region #{region_name}"
            next
          end
          reg['types'].each do |type|
            type_name = type['name']
            tiers = type['tiers']
            next if tiers.nil?
            tiers.each do |tier|
              family = tier['name']

              # hack for now until I can get capacity for fpga instances
              next if family == 'f1'
              if @@CAPACITY_HASH[family].nil?
                # 2017-11-08 family == 'c5' not supported for DH
                $stderr.puts "[fetch_ec2_dedicated_host_instance_pricing] WARNING: unable to find CAPACITY_HASH for #{family}"
                next
              end

              dhprice = tier['prices']['USD']
              @@CAPACITY_HASH[family].each do |inst_size,capacity|
                api_name, name = Ec2InstanceType.get_name(family, "#{family}.#{inst_size}", false)
                instance_type = region.add_or_update_ec2_instance_type(api_name, name)
                instance_type.update_dhi_pricing(operating_system, dhprice, capacity)
              end
            end
          end

        rescue UnknownTypeError
          $stderr.puts "[fetch_ec2_dedicated_host_instance_pricing] WARNING: encountered #{$!.message}"
        end
      end
    end
  end
end
