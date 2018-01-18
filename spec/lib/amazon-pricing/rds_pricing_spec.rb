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
      expect(AwsPricing::DatabaseType.database_sf_from_product_name?(product_name)).to be true
      expect(AwsPricing::DatabaseType.database_sf_from_engine_name_and_license_type?('oracle-se2', true)).to be true
      expect(AwsPricing::DatabaseType.database_multiaz?(display_name)).to be true
      expect(AwsPricing::DatabaseType.database_nf(display_name)).to eq(2)

      product_name = 'sqlserver-se(byol)'  # known NOT RDS SF example: 'Microsoft SQL Server Standard Edition (BYOL)'
      multiaz = false
      display_name = AwsPricing::DatabaseType.db_mapping(product_name, multiaz)
      puts "rds_sf_database-2: display_name:#{display_name}"
      #
      expect(AwsPricing::DatabaseType.database_sf?(display_name)).to be false
      expect(AwsPricing::DatabaseType.database_sf_from_product_name?(product_name)).to be false
      expect(AwsPricing::DatabaseType.database_sf_from_engine_name_and_license_type?('sqlserver-se', true)).to be false
      expect(AwsPricing::DatabaseType.database_multiaz?(display_name)).to be false
      expect(AwsPricing::DatabaseType.database_nf(display_name)).to eq(1)

      product_name = 'sqlserver-se(li)'  # known NOT RDS SF example: 'Microsoft SQL Server Standard Edition'
      multiaz = false
      display_name = AwsPricing::DatabaseType.db_mapping(product_name, multiaz)
      puts "rds_sf_database-2: display_name:#{display_name}"
      #
      expect(AwsPricing::DatabaseType.database_sf?(display_name)).to be false
      expect(AwsPricing::DatabaseType.database_sf_from_product_name?(product_name)).to be false
      expect(AwsPricing::DatabaseType.database_sf_from_engine_name_and_license_type?('sqlserver-se', false)).to be false
      expect(AwsPricing::DatabaseType.database_multiaz?(display_name)).to be false
      expect(AwsPricing::DatabaseType.database_nf(display_name)).to eq(1)

      display_name = 'NuoDB'              # unknown db, returns default non RDS SF values
      #
      expect(AwsPricing::DatabaseType.database_sf?(display_name)).to be false
      expect(AwsPricing::DatabaseType.database_sf_from_product_name?(product_name)).to be false
      expect(AwsPricing::DatabaseType.database_sf_from_engine_name_and_license_type?('NuoDB', false)).to be false
      expect(AwsPricing::DatabaseType.database_multiaz?(display_name)).to be false
      expect(AwsPricing::DatabaseType.database_nf(display_name)).to eq(1)
    end

    it 'verifies RDS SF api for product name' do
      product_name_to_size_flex_map = {
        'mysql'              => true,
        'postgres'           => true,
        'postgresql'         => true,
        'oracle-se1(li)'     => false,
        'oracle-se1(byol)'   => true,
        'oracle-se2(li)'     => false,
        'oracle-se2(byol)'   => true,
        'oracle-se(byol)'    => true,
        'oracle-ee(byol)'    => true,
        'sqlserver-ex(li)'   => false,
        'sqlserver-web(li)'  => false,
        'sqlserver-se(li)'   => false,
        'sqlserver-se(byol)' => false,
        'sqlserver-ee(li)'   => false,
        'sqlserver-ee(byol)' => false,
        'aurora'             => true,
        'aurora-postgresql'  => true,
        'mariadb'            => true
      }

      product_name_to_size_flex_map.each do |product_name, expected_value|
        expect(AwsPricing::DatabaseType.database_sf_from_product_name?(product_name)).to be expected_value
      end
    end

    it 'verifies RDS SF api for engine name and license type' do
      engine_name_and_license_type_to_size_flex_map = {
        ['mysql', false]             => true,
        ['postgres', false]          => true,
        ['postgresql', false]        => true,
        ['oracle-se1', false]        => false,
        ['oracle-se1', true]         => true,
        ['oracle-se2', false]        => false,
        ['oracle-se2', true]         => true,
        ['oracle-se', true]          => true,
        ['oracle-ee', true]          => true,
        ['sqlserver-ex', false]      => false,
        ['sqlserver-web', false]     => false,
        ['sqlserver-se', false]      => false,
        ['sqlserver-se', true]       => false,
        ['sqlserver-ee', false]      => false,
        ['sqlserver-ee', true]       => false,
        ['aurora', false]            => true,
        ['aurora-postgresql', false] => true,
        ['mariadb', false]           => true
      }

      engine_name_and_license_type_to_size_flex_map.each do |engine_and_license, expected_value|
        engine = engine_and_license.first
        license = engine_and_license.last
        expect(AwsPricing::DatabaseType.database_sf_from_engine_name_and_license_type?(engine, license)).to be expected_value
      end
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
