module AwsPricing

  class GovCloudEc2PriceList < PriceList
    GOV_CLOUD_URL = "http://aws.amazon.com/govcloud-us/pricing/ec2/"
    GOV_CLOUD_EBS_URL = "http://aws.amazon.com/govcloud-us/pricing/ebs/"

    def initialize
      super(true)
      InstanceType.populate_lookups
      get_ec2_instance_pricing
      fetch_ec2_ebs_pricing
    end

    protected

    def get_ec2_instance_pricing

      client = Mechanize.new
      page = client.get(GOV_CLOUD_URL)
      tables = page.search("//div[@class='aws-table ']")
      for i in 0..3
        create_ondemand_instances(tables[i])
      end
      
      for i in 4..9
        #create_reserved_instances(tables[i], :light)
      end
      for i in 9..22
        #create_reserved_instances(tables[i], :medium)
      end
      for i in 23..33
        #create_reserved_instances(tables[i], :heavy)
      end

    end

    # e.g. [["Prices / Hour", "Amazon Linux", "RHEL", "SLES"], ["m1.small", "$0.053", "$0.083", "$0.083"]]
    def create_ondemand_instances(table)
      rows = get_rows(table)
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
    def create_reserved_instances(table, res_type)
      rows = get_rows(table)
      operating_system = get_os(table.search(".//td/p").last.inner_text.strip)  # Wow...

      @_regions.values.each do |region|

        rows.slice(1, rows.size).each do |row|
          api_name = row[0]
          instance_type = region.get_instance_type(api_name)
          if instance_type.nil?
            api_name, name = Ec2InstanceType.get_name(nil, api_name, true)
            instance_type = region.add_or_update_ec2_instance_type(api_name, name)
          end
         instance_type.update_pricing2(operating_system, res_type, nil, row[1], row[3], row[2], row[4])
        end
      end
    end

    def fetch_ec2_ebs_pricing
      client = Mechanize.new
      page = client.get(GOV_CLOUD_EBS_URL)
      ebs_costs = page.search("//div[@class='text-box section']//li")
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
      when "Windows SQL Server Web", "Windows SQL Server Web Edition", "Windows SQL Server\n Web Edition"
        :mswinSQL
      when "Windows SQL Server Standard", "Windows SQL Server Standard Edition", "Windows SQL Server\n Standard Edition"
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
      tables = page.search("//div[@class='aws-table ']")

      # Mysql
      create_ondemand_instances(:mysql, :ondemand, false, false, get_rows(tables[0]))
      create_ondemand_instances(:mysql, :ondemand, true, false, get_rows(tables[1]))
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
      create_ondemand_instances(:oracle_se1, :ondemand, false, false, get_rows(tables[5]))
      create_ondemand_instances(:oracle_se1, :ondemand, true, false, get_rows(tables[6]))
      create_ondemand_instances(:oracle_se1, :ondemand, false, true, get_rows(tables[7]))
      create_ondemand_instances(:oracle_se1, :ondemand, true, true, get_rows(tables[8]))

      row = 9
      [false, true].each do |is_byol|
        [:light, :medium, :heavy].each do |res_type|
          no_multi_az_rows, multi_az_rows =  get_reserved_rows(get_rows(tables[9]))
          create_reserved_instances(:oracle_se1, res_type, false, is_byol, no_multi_az_rows)
          create_reserved_instances(:oracle_se1, res_type, true, is_byol, multi_az_rows)
          row += 1
        end
      end

      # SQL Server
      create_ondemand_instances(:sqlserver_ex, :ondemand, false, false, get_rows(tables[15]))
      create_ondemand_instances(:sqlserver_web, :ondemand, false, false, get_rows(tables[16]))
      create_ondemand_instances(:sqlserver_se, :ondemand, false, false, get_rows(tables[17]))
      row = 18
      [:light, :medium, :heavy].each do |restype|
        [:sqlserver_ex, :sqlserver_web, :sqlserver_se].each do |db|
          no_multi_az_rows, multi_az_rows =  get_reserved_rows(get_rows(tables[row]))
          create_reserved_instances(db, restype, false, false, no_multi_az_rows)
          create_reserved_instances(db, restype, true, false, multi_az_rows)
          row += 1
        end
      end

      # Postgres
      # Mysql
      create_ondemand_instances(:postgresql, :ondemand, false, false, get_rows(tables[31]))
      create_ondemand_instances(:postgresql, :ondemand, true, false, get_rows(tables[32]))
      row = 33
      [:light, :medium, :heavy].each do |restype|
        no_multi_az_rows, multi_az_rows =  get_reserved_rows(get_rows(tables[row]))
        create_reserved_instances(:postgresql, restype, false, false, no_multi_az_rows)
        create_reserved_instances(:postgresql, restype, true, false, multi_az_rows)
        row += 1
      end

    end

    # e.g. [["General Purpose - Previous Generation", "Price Per Hour"], ["m1.small", "$0.090"], ["m1.medium", "$0.185"]]
    def create_ondemand_instances(db_type, res_type, is_multi_az, is_byol, rows)
      @_regions.values.each do |region|
        # Skip header row
        rows.each do |row|
          api_name = row[0]
          unless api_name.include?("db.")
            $stderr.puts "Skipping row containing non-db type: #{api_name}"
            next
          end
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
          unless api_name.include?("db.")
            $stderr.puts "Skipping row containing non-db type: #{api_name}"
            next
          end
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
end
