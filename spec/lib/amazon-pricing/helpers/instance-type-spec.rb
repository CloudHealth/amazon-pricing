require 'spec_helper'
require 'amazon-pricing/helpers/instance-type'
require 'amazon-pricing/definitions/ec2-instance-type'

describe 'AwsPricing::Helper::InstanceType' do
  context 'family_members' do

    # get a list of supported instance types, and filter out anything with more than 2 parts to its name (to get
    # rif of alias-y things like cache.m3.large and db.m3.large)
    types = AwsPricing::Ec2InstanceType.instance_eval("@Network_Performance").keys.reject {|k| k =~ /.*\..*\..*/}

    # test that we can get the family member for each type
    types.each do |type|
      it "should be able to get family members for #{type}" do
        AwsPricing::Helper::InstanceType.family_members(type).should_not eq(nil)
      end
    end
  end

  it 'should lookup *xl instance as *xlarge' do
    expect(AwsPricing::Helper::InstanceType.api_name_to_nf('xl')).to(
        eq(AwsPricing::Helper::InstanceType.api_name_to_nf('xlarge')))
    expect(AwsPricing::Helper::InstanceType.api_name_to_nf('xl')).to_not eq nil
    [2, 3, 4, 6, 8, 9, 10, 12, 16, 18, 24, 32].each do |size|
      nf = AwsPricing::Helper::InstanceType.api_name_to_nf("#{size}xl")
      expect(nf).to_not eq nil
      expect(nf).to eq(AwsPricing::Helper::InstanceType.api_name_to_nf("#{size}xlarge"))
    end
  end
end
