require 'spec_helper'

describe AwsPricing::RdsPriceList do
  before(:all) do
    @pricing = AwsPricing::RdsPriceList.new
    @region_name = %w(us-east us-west us-west-2 eu-ireland apac-sin apac-syd apac-tokyo sa-east-1)
    @db_types = [:mysql, :oracle, :oracle_byol, :sqlserver, :sqlserver_express, :sqlserver_web, :sqlserver_byol]
  end

  describe 'new' do
    it 'RdsPriceList.new should return the valid response', broken: true do
      @pricing.regions.each do |region|
        # response should have valid region
        expect(@region_name).to include(region.name)
        # Result have valid db name
        expect(@db_types).to include(region.rds_instance_types.first.category_types.first.name)
        # values should not be nil
        region.rds_instance_types.first.category_types.first.ondemand_price_per_hour.should_not be_nil
        region.rds_instance_types.first.category_types.first.light_price_per_hour_1_year.should_not be_nil
        region.rds_instance_types.first.category_types.first.medium_price_per_hour_1_year.should_not be_nil
        region.rds_instance_types.first.category_types.first.heavy_price_per_hour_1_year.should_not be_nil
      end
    end
  end

  describe '::get_api_name' do
    it "raises an UnknownTypeError on an unexpected instance type" do
      expect {
        AwsPricing::RdsInstanceType::get_name 'QuantumODI', 'huge'
      }.to raise_error(AwsPricing::UnknownTypeError)
    end
  end

  describe 'rds_sf_database' do
    it "verifies RDS SF api for database name" do
      # tests database display_name APIs {database_sf?, database_multiaz?, database_nf},
      #   and also adds indirect testing of #db_mapping too
      product_name = 'oracle-se2(byol)'  # known RDS SF multiaz example: 'Oracle Database Standard Edition Two (BYOL Multi-AZ)'
      multiaz = true
      display_name = AwsPricing::DatabaseType.db_mapping(product_name, multiaz)
      puts "rds_sf_database-1: display_name:#{display_name}"
      #
      expect(AwsPricing::DatabaseType.database_sf?(display_name)).to be true
      expect(AwsPricing::DatabaseType.database_multiaz?(display_name)).to be true
      expect(AwsPricing::DatabaseType.database_nf(display_name)).to eq(2)

      product_name = 'sqlserver-se(byol)'  # known NOT RDS SF example: 'Microsoft SQL Server Standard Edition (BYOL)'
      multiaz = false
      display_name = AwsPricing::DatabaseType.db_mapping(product_name, multiaz)
      puts "rds_sf_database-2: display_name:#{display_name}"
      #
      expect(AwsPricing::DatabaseType.database_sf?(display_name)).to be false
      expect(AwsPricing::DatabaseType.database_multiaz?(display_name)).to be false
      expect(AwsPricing::DatabaseType.database_nf(display_name)).to eq(1)

      display_name = 'NuoDB'              # unknown db, returns default non RDS SF values
      #
      expect(AwsPricing::DatabaseType.database_sf?(display_name)).to be false
      expect(AwsPricing::DatabaseType.database_multiaz?(display_name)).to be false
      expect(AwsPricing::DatabaseType.database_nf(display_name)).to eq(1)
    end
  end

  describe 'rds_sf_operation' do
    it "verifies RDS SF api for operation name" do
      # tests operation name APIs {operation_sf?, operation_nf}
      operation_name = 'CreateDBInstance:0002'  # known RDS SF: 'MySQL Community Edition (Multi-AZ)'
      multiaz = true
      #
      expect(AwsPricing::DatabaseType.operation_sf?(operation_name, multiaz)).to be true
      expect(AwsPricing::DatabaseType.operation_nf(operation_name,  multiaz)).to eq(2)
      multiaz = false
      expect(AwsPricing::DatabaseType.operation_sf?(operation_name, multiaz)).to be true
      expect(AwsPricing::DatabaseType.operation_nf(operation_name,  multiaz)).to eq(1)    #multiaz *not* encoded in operation_name

      operation_name = 'CreateDBInstance:0008'  # known non RDS SF: 'Microsoft SQL Server Standard Edition (BYOL)'
      multiaz = false
      #
      expect(AwsPricing::DatabaseType.operation_sf?(operation_name, multiaz)).to be false
      expect(AwsPricing::DatabaseType.operation_nf(operation_name,  multiaz)).to eq(1)
      multiaz = true
      expect(AwsPricing::DatabaseType.operation_sf?(operation_name, multiaz)).to be false
      expect(AwsPricing::DatabaseType.operation_nf(operation_name,  multiaz)).to eq(1)    #multiaz *not* encoded in operation_name

      operation_name = 'CreateDBInstance:9999'  # unknown operation, returns default non RDS SF values
      multiaz = false
      #
      expect(AwsPricing::DatabaseType.operation_sf?(operation_name, multiaz)).to be false
      expect(AwsPricing::DatabaseType.operation_nf(operation_name,multiaz)).to eq(1)
      multiaz = true
      expect(AwsPricing::DatabaseType.operation_sf?(operation_name, multiaz)).to be false
      expect(AwsPricing::DatabaseType.operation_nf(operation_name,multiaz)).to eq(1)    #multiaz *not* encoded in operation_name
    end
  end

  describe 'get_breakeven_months' do 
    it "test_fetch_all_breakeven_months" do
      @pricing.regions.each do |region|
        region.rds_instance_types.each do |instance|
          [:year1, :year3].each do |term|
             [:light, :medium, :heavy].each do |res_type|
               [:mysql, :postgresql, :oracle_se1, :oracle_se, :oracle_ee, :sqlserver_se, :sqlserver_ee].each do |db|
                  if db == :postgresql
                    if :heavy
                      AwsPricing::DatabaseType.get_available_types(db).each do |deploy_type|
                        next if not instance.available?(db, res_type, deploy_type == :multiaz, false)
                        instance.get_breakeven_month(db, res_type, term, deploy_type == :multiaz, false).should_not be_nil
                      end
                    end
                  else
                    AwsPricing::DatabaseType.get_available_types(db).each do |deploy_type|
                      if deploy_type == :byol_multiaz
                        next if not instance.available?(db, res_type, true, true)
                        instance.get_breakeven_month(db, res_type, term, true, true).should_not be_nil
                      else 
                        next if not instance.available?(db, res_type, deploy_type == :multiaz, deploy_type == :byol)
                        instance.get_breakeven_month(db, res_type, term, deploy_type == :multiaz, deploy_type == :byol).should_not be_nil
                      end  
                    end
                  end                      
               end
             end
          end          
        end
      end
    end
  end
end
