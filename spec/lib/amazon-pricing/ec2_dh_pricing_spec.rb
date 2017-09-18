require 'spec_helper'

describe AwsPricing::Ec2DedicatedHostPriceList do

  before(:all) do
    @pricing = AwsPricing::Ec2DedicatedHostPriceList.new
  end

  def validate_price_in_region region
    # Result have valid node name
    region.ec2_dh_types.each do |dh_type|
      expect(dh_type.region.ec2_dh_types[0].category_types[:linux].name).to eq(:linux)
      expect(dh_type.region.ec2_dh_types[0].category_types[:linux].ondemand_price_per_hour.class).to eq(Float)
    end
  end

  describe 'new' do
    it 'Ec2DedicatedHostPriceList.new should return valid response' do
      @pricing.regions.each do |region|
        validate_price_in_region region
      end
    end
  end

end
