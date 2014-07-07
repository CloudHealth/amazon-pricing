
require 'json'
require 'net/http'
require 'mechanize'

Dir[File.join(File.dirname(__FILE__), 'amazon-pricing/*.rb')].sort.each { |lib| require lib }

#--
# Amazon Web Services Pricing Ruby library
#
# Ruby Gem Name::  amazon-pricing
# Author::    Joe Kinsella (mailto:joe.kinsella@gmail.com)
# Copyright:: Copyright (c) 2011-2013 CloudHealth
# License::   Distributes under the same terms as Ruby
# Home::      http://github.com/CloudHealth/amazon-pricing
#++
module AwsPricing

  # PriceList provides the primary interface for retrieving AWS pricing.
  # Upon instantiating a PriceList object, all the corresponding pricing
  # information will be retrieved from Amazon via currently undocumented
  # json APIs.
  class PriceList
    attr_accessor :regions

    def get_region(name)
      @_regions[@@Region_Lookup[name] || name]
    end

    def regions
      @_regions.values
    end

    def get_instance_types
      instance_types = []
      @_regions.each do |region|
        region.ec2_instance_types.each do |instance_type|
          instance_types << instance_type
        end
      end
      instance_types
    end

    def get_instance_type(region_name, api_name)
      region = get_region(region_name)
      raise "Region #{region_name} not found" if region.nil?
      region.get_instance_type(api_name)
    end

    def self.fetch_url(url)
      uri = URI.parse(url)
      page = Net::HTTP.get_response(uri)
      # Now that AWS switched from json to jsonp, remove first/last lines
      body = page.body.gsub("callback(", "").reverse.sub(")", "").reverse
      if body.split("\n").last == ";"
        # Now remove one more line (rds is returning ";", ec2 empty line)
        body = body.reverse.sub(";", "").reverse
      elsif body[-1] == ";"
        body.chop!
      end

      begin
        JSON.parse(body)
      rescue JSON::ParserError
        # Handle "json" with keys that are not quoted
        # When we get {foo: "1"} instead of {"foo": "1"}
        # http://stackoverflow.com/questions/2060356/parsing-json-without-quoted-keys
        JSON.parse(body.gsub(/(\w+)\s*:/, '"\1":'))
      end
    end

    protected

    attr_accessor :_regions

    def add_region(region)
      @_regions[region.name] = region
    end

    def find_or_create_region(name)
      region = get_region(name)
      if region.nil?
        region = Region.new(name)
        add_region(region)
      end
      region
    end

    EC2_BASE_URL = "http://a0.awsstatic.com/pricing/1/ec2/"
    EBS_BASE_URL = "http://a0.awsstatic.com/pricing/1/ebs/"
    RDS_BASE_URL = "http://a0.awsstatic.com/pricing/1/rds/"

    # Lookup allows us to map to AWS API region names
    @@Region_Lookup = {
      'us-east-1' => 'us-east',
      'us-west-1' => 'us-west',
      'us-west-2' => 'us-west-2',
      'eu-west-1' => 'eu-ireland',
      'ap-southeast-1' => 'apac-sin',
      'ap-southeast-2' => 'apac-syd',
      'ap-northeast-1' => 'apac-tokyo',
      'sa-east-1' => 'sa-east-1'
    }

  end


  class GovCloudEc2PriceList < PriceList
    GOV_CLOUD_URL = "http://aws.amazon.com/govcloud-us/pricing/ec2/"
    GOV_CLOUD_EBS_URL = "http://aws.amazon.com/govcloud-us/pricing/ebs/"

    def initialize
      @_regions = {}
      @_regions["us-gov-west-1"] = Region.new("us-gov-west-1")
      InstanceType.populate_lookups
      get_ec2_instance_pricing
      fetch_ec2_ebs_pricing
    end

    protected

    def get_ec2_instance_pricing

      client = Mechanize.new
      page = client.get(GOV_CLOUD_URL)
      tables = page.search("//div[@class='aws-table section']")
      create_ondemand_instances(get_rows(tables[0]))
      create_ondemand_instances(get_rows(tables[1]))
      
      for i in 2..7
        create_reserved_instances(get_rows(tables[i]), :light)
      end
      for i in 8..13
        create_reserved_instances(get_rows(tables[i]), :medium)
      end
      for i in 14..19
        create_reserved_instances(get_rows(tables[i]), :heavy)
      end

    end

    # e.g. [["Prices / Hour", "Amazon Linux", "RHEL", "SLES"], ["m1.small", "$0.053", "$0.083", "$0.083"]]
    def create_ondemand_instances(rows)
      header = rows[0]
      @_regions.values.each do |region|

        rows.slice(1, rows.size).each do |row|
          api_name = row[0]
          instance_type = region.get_ec2_instance_type(api_name)
          if instance_type.nil?
            api_name, name = Ec2InstanceType.get_name(nil, row[0], false)
            instance_type = region.add_or_update_ec2_instance_type(api_name, name)
          end
          instance_type.update_pricing2(get_os(header[1]), :ondemand, row[1])
          instance_type.update_pricing2(get_os(header[2]), :ondemand, row[2])
          instance_type.update_pricing2(get_os(header[3]), :ondemand, row[3])
        end
      end
    end

    # e.g. [["RHEL", "1 yr Term Upfront", "1 yr TermHourly", "3 yr TermUpfront", "3 yr Term Hourly"], ["m1.small", "$68.00", "$0.099", "$105.00", "$0.098"]]
    def create_reserved_instances(rows, res_type)
      header = rows[0]
      operating_system = get_os(header[0])
      @_regions.values.each do |region|

        rows.slice(1, rows.size).each do |row|
          api_name = row[0]
          instance_type = region.get_instance_type(api_name)
          if instance_type.nil?
            api_name, name = Ec2InstanceType.get_name(nil, row[0], true)
            instance_type = region.add_or_update_ec2_instance_type(api_name, name)
          end
         instance_type.update_pricing2(operating_system, res_type, nil, row[1], row[3], row[2], row[4])
        end
      end
    end

    def fetch_ec2_ebs_pricing
      client = Mechanize.new
      page = client.get(GOV_CLOUD_EBS_URL)
      ebs_costs = page.search("//div[@class='text section']//li")
      @_regions.values.each do |region|
        region.ebs_price = EbsPrice.new(region)
        region.ebs_price.preferred_per_gb = get_ebs_price(ebs_costs[1])
        region.ebs_price.preferred_per_iops = get_ebs_price(ebs_costs[2])
        region.ebs_price.standard_per_gb = get_ebs_price(ebs_costs[3])
        region.ebs_price.standard_per_million_io = get_ebs_price(ebs_costs[4])
        region.ebs_price.ssd_per_gb = nil
        region.ebs_price.s3_snaps_per_gb = get_ebs_price(ebs_costs[5])
      end

    end

    # e.g. $0.065 per GB-Month of provisioned storage
    def get_ebs_price(xml_element)
      tokens = xml_element.text.split(" ")
      tokens[0].gsub("$", "").to_f
    end

    def get_os(val)
      case val
      when "Amazon Linux"
        :linux
      when "RHEL"
        :rhel
      when "SLES"
        :sles
      when "Windows"
        :mswin
      when "Windows SQL Server Web", "Windows SQL Server Web Edition"
        :mswinSQL
      when "Windows SQL Server Standard", "Windows SQL Server Standard Edition"
        :mswinSQLWeb
      else
        raise "Unable to identify operating system '#{val}'"
      end
    end

    def get_rows(html_table)
      rows = []
      html_table.search(".//tr").each do |tr|
        row = []
        tr.search(".//td").each do |td|
         row << td.inner_text.strip.sub("\n", " ").sub("  ", " ")
        end
        next if row.size == 1
        rows << row unless row.empty?
      end
      rows
    end  
  end


  class GovCloudRdsPriceList < PriceList
    GOV_CLOUD_URL = "http://aws.amazon.com/govcloud-us/pricing/rds/"

    def initialize
      @_regions = {}
      @_regions["us-gov-west-1"] = Region.new("us-gov-west-1")
      InstanceType.populate_lookups
      get_rds_instance_pricing
    end

    protected
    #@@DB_TYPE = [:mysql, :postgresql, :oracle, :sqlserver]
    #@@RES_TYPES = [:light, :medium, :heavy]
   
    def get_rds_instance_pricing

      client = Mechanize.new
      page = client.get(GOV_CLOUD_URL)
      tables = page.search("//div[@class='aws-table section']")

      create_ondemand_instances(:mysql, :ondemand, false, false, get_rows(tables[0]))
      create_ondemand_instances(:mysql, :ondemand, true, false, get_rows(tables[1]))
      # Mysql
      no_multi_az_rows, multi_az_rows =  get_reserved_rows(get_rows(tables[2]))
      create_reserved_instances(:mysql, :light, false, false, no_multi_az_rows)
      create_reserved_instances(:mysql, :light, true, false, multi_az_rows)
      no_multi_az_rows, multi_az_rows =  get_reserved_rows(get_rows(tables[3]))
      create_reserved_instances(:mysql, :medium, false, false, no_multi_az_rows)
      create_reserved_instances(:mysql, :medium, true, false, multi_az_rows)
      no_multi_az_rows, multi_az_rows =  get_reserved_rows(get_rows(tables[4]))
      create_reserved_instances(:mysql, :heavy, false, false, no_multi_az_rows)
      create_reserved_instances(:mysql, :heavy, true, false, multi_az_rows)
      # Oracle
      #no_multi_az_rows, multi_az_rows =  get_reserved_rows(get_rows(tables[7]))
      #create_reserved_instances(:oracle_se1, :ondemand, false, false, no_multi_az_rows)
      #create_reserved_instances(:oracle_se1, :ondemand, true, false, multi_az_rows)
    end

    # e.g. [["General Purpose - Previous Generation", "Price Per Hour"], ["m1.small", "$0.090"], ["m1.medium", "$0.185"]]
    def create_ondemand_instances(db_type, res_type, is_multi_az, is_byol, rows)
      @_regions.values.each do |region|
        # Skip header row
        rows.slice(1, rows.size).each do |row|
          api_name = row[0]
          instance_type = region.get_rds_instance_type(api_name)
          if instance_type.nil?
            api_name, name = RdsInstanceType.get_name(nil, row[0], false)
            instance_type = region.add_or_update_rds_instance_type(api_name, name)
          end
          instance_type.update_pricing2(db_type, res_type, is_multi_az, is_byol, row[1])
        end
      end
    end

    # e.g. [[" ", "1 yr Term", "3 yr Term"], [" ", "Upfront", "Hourly", "Upfront", "Hourly"], ["m1.small", "$159", "$0.035", "$249", "$0.033"]]
    def create_reserved_instances(db_type, res_type, is_multi_az, is_byol, rows)
      @_regions.values.each do |region|
        rows.each do |row|
          api_name = row[0]
          instance_type = region.get_rds_instance_type(api_name)
          if instance_type.nil?
            api_name, name = RdsInstanceType.get_name(nil, row[0], true)
            instance_type = region.add_or_update_rds_instance_type(api_name, name)
          end
         instance_type.update_pricing2(db_type, res_type, is_multi_az, is_byol, nil, row[1], row[3], row[2], row[4])
        end
      end
    end

    def get_reserved_rows(rows)
      # Skip 2 header rows
      new_rows = rows.slice(2, rows.size)
      no_multi_az_rows = new_rows.slice(0, new_rows.size / 2)
      multi_az_rows = new_rows.slice(new_rows.size / 2, new_rows.size / 2)
      [no_multi_az_rows, multi_az_rows]
    end

    def get_rows(html_table)
      rows = []
      html_table.search(".//tr").each do |tr|
        row = []
        tr.search(".//td").each do |td|
         row << td.inner_text.strip.sub("\n", " ").sub("  ", " ")
        end
        # Various <tR> elements contain labels which have only 1 <td> - except heavy multi-az ;)
        next if row.size == 1 || row[0].include?("Multi-AZ Deployment")
        rows << row unless row.empty?
      end
      rows
    end  
  end



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

  class RdsPriceList < PriceList
    
    def initialize
      @_regions = {}
      InstanceType.populate_lookups
      get_rds_on_demand_instance_pricing
      get_rds_reserved_instance_pricing
    end

    protected

    @@DB_TYPE = [:mysql, :postgresql, :oracle, :sqlserver]
    @@RES_TYPES = [:light, :medium, :heavy]
    
    @@OD_DB_DEPLOY_TYPE = {
                           :mysql=> {:mysql=>["standard","multiAZ"]},
                           :postgresql=> {:postgresql=>["standard","multiAZ"]},
                           :oracle=> {:oracle_se1=>["li-standard","li-multiAZ","byol-standard","byol-multiAZ"], :oracle_se=>["byol-standard","byol-multiAZ"], :oracle_ee=>["byol-standard","byol-multiAZ"]},
                           :sqlserver=> {:sqlserver_ex=>["li-ex"], :sqlserver_web=>["li-web"], :sqlserver_se=>["li-se", "byol"], :sqlserver_ee=>["byol"]}
                        }


    @@RESERVED_DB_DEPLOY_TYPE = {
                           :oracle=> {:oracle_se1=>["li","byol"], :oracle_se=>["byol"], :oracle_ee=>["byol"]},
                           :sqlserver=> {:sqlserver_ex=>["li-ex"], :sqlserver_web=>["li-web"], :sqlserver_se=>["li-se","byol"], :sqlserver_ee=>["byol"]}
                          }

    
    def is_multi_az?(type)
      return true if type.match("multiAZ")
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

            if [:mysql, :postgresql, :oracle].include? db
              fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{dp_type}-deployments.min.js",:ondemand, db_type, is_byol)
            elsif db == :sqlserver
              fetch_on_demand_rds_instance_pricing(RDS_BASE_URL+"#{db}/sqlserver-#{dp_type}-ondemand.min.js",:ondemand, db_type, is_byol)
            end
          end
        }
      end
    end

    def get_rds_reserved_instance_pricing
       @@DB_TYPE.each do |db|
        if [:mysql, :postgresql].include? db
          @@RES_TYPES.each do |res_type|
            if db == :postgresql and res_type == :heavy
              fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{res_type}-utilization-reserved-instances.min.js", res_type, db, false)
            elsif db == :mysql
              fetch_reserved_rds_instance_pricing(RDS_BASE_URL+"#{db}/pricing-#{res_type}-utilization-reserved-instances.min.js", res_type, db, false)
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
              end    
            end            
          }
        end
      end
    end

    def fetch_on_demand_rds_instance_pricing(url, type_of_rds_instance, db_type, is_byol)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['types'].each do |type|
          type['tiers'].each do |tier|
            begin
              #
              # this is special case URL, it is oracle - multiAZ type of deployment but it doesn't have mutliAZ attributes in json.
              if url == "http://aws.amazon.com/rds/pricing/oracle/pricing-li-multiAZ-deployments.min.js"
                is_multi_az = true
              else
                is_multi_az = is_multi_az? type["name"]
              end              
              api_name, name = RdsInstanceType.get_name(type["name"], tier["name"], type_of_rds_instance != :ondemand)
              
              instance_type = region.add_or_update_rds_instance_type(api_name, name)
              instance_type.update_pricing(db_type, type_of_rds_instance, tier, is_multi_az, is_byol)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end                        
      end
    end

    def fetch_reserved_rds_instance_pricing(url, type_of_rds_instance, db_type, is_byol)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = find_or_create_region(region_name)
        reg['instanceTypes'].each do |type|
          type['tiers'].each do |tier|
            begin
                is_multi_az = is_multi_az? type["type"]
                api_name, name = RdsInstanceType.get_name(type["type"], tier["size"], true)
                
                instance_type = region.add_or_update_rds_instance_type(api_name, name)
                instance_type.update_pricing(db_type, type_of_rds_instance, tier, is_multi_az, is_byol)
            rescue UnknownTypeError
              $stderr.puts "WARNING: encountered #{$!.message}"
            end
          end
        end
      end
    end                              
  end
end