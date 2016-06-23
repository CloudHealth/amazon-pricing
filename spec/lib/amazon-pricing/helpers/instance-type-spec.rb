require 'spec_helper'
require 'amazon-pricing/helpers/instance-type'
require 'amazon-pricing/definitions/ec2-instance-type'

describe 'AwsPricing::Helper::InstanceType' do
  let(:dummy_class) { Class.new { include AwsPricing::Helper::InstanceType } }
  let(:helper) {dummy_class.new }

  context 'family_members' do

    # get a list of supported instance types, and filter out anything with more than 2 parts to its name (to get
    # rif of alias-y things like cache.m3.large and db.m3.large)
    types = AwsPricing::Ec2InstanceType.instance_eval("@Network_Performance").keys.reject {|k| k =~ /.*\..*\..*/}
    puts types

    # test that we can get the family member for each type
    types.each do |type|
      class_eval %*
        it "should be able to get family members for #{type}" do
          helper.family_members(type).should_not eq(nil)
        end
      *
    end
  end
end