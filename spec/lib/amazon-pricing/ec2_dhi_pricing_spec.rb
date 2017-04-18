require 'spec_helper'

describe AwsPricing::Ec2DedicatedHostInstancePriceList do

  before(:all) do
    @pricing = AwsPricing::Ec2DedicatedHostInstancePriceList.new
    @dh_pricing = AwsPricing::Ec2DedicatedHostPriceList.new
  end

  def validate_price_in_region region
    # Result have valid node name
    region.ec2_instance_types.each do |inst_type|
      expect(inst_type.api_name).to match(/[[:alpha:]][[:alpha:]]./)
      expect(inst_type.category_types).to have_exactly(@pricing.os_types.length).items
      expect(inst_type.category_types[0].price_per_hour.class).to eq(Float)

      family_name = inst_type.api_name.split('.').first
      dh_region_arr = @dh_pricing.regions.select { |reg| reg.name == region.name }
      expect(dh_region_arr).to have_exactly(1).items
      dh_region = dh_region_arr[0]
      dh_price_per_hour = dh_region.ec2_dh_types[0].price_per_hour(:linux, :ondemand)
      dh_dh_type_arr = dh_region.ec2_dh_types.select { |type| type.api_name == family_name }
      expect(dh_dh_type_arr).to have_exactly(1).items
      dh_dh_type = dh_dh_type_arr[0]
      expect(inst_type.category_types[0].price_per_hour).to be <= dh_dh_type.category_types[:linux].ondemand_price_per_hour
    end
  end

  describe 'new' do
    it 'Ec2DedicatedHostInstancePriceList.new should return valid response' do
      @pricing.regions.each do |region|
        validate_price_in_region region
      end
    end
  end

end
