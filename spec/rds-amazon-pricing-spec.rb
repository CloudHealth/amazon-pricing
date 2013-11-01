require 'amazon-pricing'
require 'amazon-pricing/instance-type'

describe AwsPricing::RdsPriceList do

  before do 
  	@region_name = ['us-east', 'us-west', 'us-west-2', 'eu-ireland', 'apac-sin', 'apac-syd', 'apac-tokyo', 'sa-east-1']
  	@db_types = [:mysql, :oracle, :sqlserver]
  end

  describe 'new' do
    it 'RdsPriceList.new should return the valid response' do 
      result = AwsPricing::RdsPriceList.new
      result.regions.each do |region|
      	# response should have valid region
      	expect(@region_name).to include(region.name)
      	# Result have valid db name
      	expect(@db_types).to include(region.instance_types.first.category_types.first.name)
      	# values should not be nil
        region.instance_types.first.category_types.first.ondemand_standard_price_per_hour.should_not be_nil
      	region.instance_types.first.category_types.first.li_standard_light_price_per_hour_1_year.should_not be_nil
      	region.instance_types.first.category_types.first.li_standard_medium_price_per_hour_1_year.should_not be_nil
      	region.instance_types.first.category_types.first.li_standard_heavy_price_per_hour_1_year.should_not be_nil
      end
    end
  end

  describe '::get_api_name' do
    it "raises an UnknownTypeError on an unexpected instance type" do
      expect {
        AwsPricing::InstanceType::get_name 'QuantumODI', 'huge'
      }.to raise_error(AwsPricing::UnknownTypeError)
    end
  end
end

