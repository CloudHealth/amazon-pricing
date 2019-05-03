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

  it 'should return correct NF values' do
    expected_nf_values = {
        "nano"    => 0.25,
        "micro"   => 0.5,
        "small"   => 1,
        "medium"  => 2,
        "large"   => 4,
        "xlarge"  => 8,
        "2xlarge" => 16,
        "3xlarge" => 24,
        "4xlarge" => 32,
        "6xlarge" => 48,
        "8xlarge" => 64,
        "9xlarge" => 72,
        "10xlarge" => 80,
        "12xlarge" => 96,
        "16xlarge" => 128,
        "18xlarge" => 144,
        "24xlarge" => 192,
        "32xlarge" => 256,
        }
      metal_nf_values = {
        'u-6tb1.metal' => 896,
        'u-9tb1.metal' => 896,
        'u-12tb1.metal' => 896,
        'i3.metal' => 128,
        'm5.metal' => 192,
        'm5d.metal' => 192,
        'r5.metal' => 192,
        'r5d.metal' => 192,
        'z1d.metal' => 96
      }

      # test famliies with metal instance
      test_families = ['r5', 'm5', 'z1d']
      test_families.each do | instance_family |
        expected_nf_values.each do | test_size, nf_value |
          api_name = instance_family + '.' + test_size
          expect(AwsPricing::Helper::InstanceType.api_name_to_nf(api_name)).to eq nf_value
        end
        expect(AwsPricing::Helper::InstanceType.api_name_to_nf(instance_family + '.' + 'metal')).to eq metal_nf_values[instance_family + '.' + 'metal']
      end

      # test instance family without metal size; should return nil
      instance_family = 't3'
      expected_nf_values.each do | test_size, nf_value |
        api_name = instance_family + '.' + test_size
        expect(AwsPricing::Helper::InstanceType.api_name_to_nf(api_name)).to eq nf_value
      end
      expect(AwsPricing::Helper::InstanceType.api_name_to_nf(instance_family + '.' + 'metal')).to eq nil
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
