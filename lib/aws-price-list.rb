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

end