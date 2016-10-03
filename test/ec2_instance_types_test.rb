#!/usr/bin/env ruby

#--
# Amazon Web Services Pricing Ruby library
#
# Ruby Gem Name::  amazon-pricing
# Author::    Joe Kinsella (mailto:joe.kinsella@gmail.com)
# Copyright:: Copyright (c) 2011-2013 CloudHealth
# License::   Distributes under the same terms as Ruby
# Home::      http://github.com/CloudHealth/amazon-pricing
#++

$: << File.expand_path(File.dirname(__FILE__))
require 'helper'
require 'test-unit'

class TestEc2InstanceTypes < Test::Unit::TestCase
  def setup
    #This is expensive, so only do once.
    @@ec2_pricing ||= AwsPricing::Ec2PriceList.new
  end

  def test_name_lookup
    @@ec2_pricing.regions.each do |region|
      assert_not_nil region.name

      region.ec2_instance_types.each do |instance|
        assert_not_nil(instance.api_name)
        assert_not_nil(instance.name)
      end
    end
  end

  def test_unavailable
    # Validate instance types in specific regions are not available
    #pricing = AwsPricing::PriceList.new
    #region = pricing.get_region('apac-tokyo')
    #assert !region.instance_type_available?(:on_demand, 'cc1.4xlarge')
    true
  end

  def test_available
    # Validate instance types in specific regions are available
    region = @@ec2_pricing.get_region('us-east')
    assert region.instance_type_available?('m3.large')
  end

  def test_available_x1
    # Validate instance types in specific regions are available
    region = @@ec2_pricing.get_region('us-east')
    assert !region.instance_type_available?('x1.99xlarge')  #bogus x1
    assert region.instance_type_available?('x1.32xlarge')   #test valid x1 available
  end

  def test_available_m4_16xlarge
    # Validate instance types in specific regions are available
    region = @@ec2_pricing.get_region('us-east')
    assert region.instance_type_available?('m4.16xlarge')   #test valid m4.16x available
  end

  def test_available_p2_16xlarge
    # Validate instance types in specific regions are available
    region = @@ec2_pricing.get_region('us-east')
    assert region.instance_type_available?('p2.16xlarge')   #test valid p2.16x available
  end


  def test_fetch_all_breakeven_months
    @@ec2_pricing.regions.each do |region|
      region.ec2_instance_types.each do |instance|
        instance.operating_systems.each do |os|
          [:light, :medium, :heavy].each do |res_type|
            next if not instance.available?(res_type)
            assert_not_nil(os.get_breakeven_month(res_type, :year1))
            assert_not_nil(os.get_breakeven_month(res_type, :year3))
          end
        end
      end
    end
  end

  def test_breakeven_month
    region = @@ec2_pricing.get_region('us-east')
    instance = region.get_ec2_instance_type('m3.large')
    bem = instance.get_breakeven_month(:linux, :heavy, :year1)
    assert bem == 7
  end

  def test_memory
    # Validate instance types in specific regions are available
    region = @@ec2_pricing.get_region('us-east')
    instance = region.get_ec2_instance_type('m3.large')
    assert instance.memory_in_mb == 7500
  end

  def test_non_standard_region_name
    region = @@ec2_pricing.get_region('eu-west-1')
    instance = region.get_ec2_instance_type('m3.large')
    assert instance.memory_in_mb == 7500
  end

  def test_ebs
    region = @@ec2_pricing.get_region('us-east-1')
    # next two prices are no longer provided by aws (May 09, 2016)
    assert region.ebs_price.standard_per_gb == 0.05
    assert region.ebs_price.standard_per_million_io == 0.05
    assert region.ebs_price.preferred_per_gb == 0.125
    assert region.ebs_price.preferred_per_iops == 0.065
    assert region.ebs_price.s3_snaps_per_gb == 0.05
    # next two prices were added by aws (May 09, 2016)
    assert region.ebs_price.ebs_optimized_hdd_per_gb == 0.045
    assert region.ebs_price.ebs_cold_hdd_per_gb == 0.025

  end

  def test_ebs_not_null
    @@ec2_pricing.regions.each do |region|
      # Everyone should have standard pricing
      # next two prices are no longer provided by aws (May 09, 2016) 
      assert_not_nil region.ebs_price.standard_per_gb
      assert_not_nil region.ebs_price.standard_per_million_io
      assert_not_nil region.ebs_price.preferred_per_gb
      assert_not_nil region.ebs_price.preferred_per_iops
      assert_not_nil region.ebs_price.ebs_optimized_hdd_per_gb
      assert_not_nil region.ebs_price.ebs_cold_hdd_per_gb
      assert_not_nil region.ebs_price.s3_snaps_per_gb
    end
  end

  def test_virtual_cores
    region = @@ec2_pricing.get_region('us-east')
    instance = region.get_ec2_instance_type('m3.large')
    assert instance.virtual_cores == 2
  end

  def test_new_reservation_types
    region = @@ec2_pricing.get_region('us-east')
    instance = region.get_ec2_instance_type('c3.large')
    os = instance.get_operating_system(:linux)
    assert os.ondemand_price_per_hour == 0.105
    assert os.partialupfront_prepay_1_year == 326
    assert os.allupfront_prepay_1_year == 542
    assert os.partialupfront_prepay_3_year == 508
    assert os.allupfront_prepay_3_year == 1020
    assert os.noupfront_effective_rate_1_year == 0.0730
    assert os.partialupfront_effective_rate_1_year == 0.0632
    assert os.allupfront_effective_rate_1_year == 0.0619
    assert os.partialupfront_effective_rate_3_year == 0.0413
    assert os.allupfront_effective_rate_3_year == 0.0388
  end

  def test_new_reservation_types_for_legacy_instance
    region = @@ec2_pricing.get_region('us-east')
    instance = region.get_ec2_instance_type('m2.4xlarge')
    os = instance.get_operating_system(:linux)
    assert os.ondemand_price_per_hour == 0.980
    assert os.partialupfront_prepay_1_year == 1894
    assert os.allupfront_prepay_1_year == 3255
    assert os.partialupfront_prepay_3_year == 2875
    assert os.allupfront_prepay_3_year == 5839
    assert os.noupfront_effective_rate_1_year == 0.444
    assert os.partialupfront_effective_rate_1_year == 0.3792
    assert os.allupfront_effective_rate_1_year == 0.3716
    assert os.partialupfront_effective_rate_3_year == 0.2364
    assert os.allupfront_effective_rate_3_year == 0.2222
  end

  def test_bad_data
    # Someone at AWS is fat fingering the pricing data and putting the text "os" where there should be the actual operating system (e.g. "linux") - see http://a0.awsstatic.com/pricing/1/ec2/linux-od.min.js
    @@ec2_pricing.regions.each do |region|
      region.ec2_instance_types.each do |instance|
        instance.operating_systems.each do |os|
          #assert os.ondemand_price_per_hour.nil? && (!os.light_price_per_hour_1_year.nil? || !os.medium_price_per_hour_1_year.nil? || !os.heavy_price_per_hour_1_year.nil?)
        end
      end
    end
  end

  def test_govcloud_cc8xlarge_issue
    obj = @@ec2_pricing.get_instance_type('us-gov-west-1', 'm3.large')
    assert obj.api_name == 'm3.large'
  end

  def test_govcloud_memory
    # Validate instance types in specific regions are available
    region = @@ec2_pricing.get_region('us-gov-west-1')
    instance = region.get_ec2_instance_type('m3.large')
    assert instance.memory_in_mb == 7500
  end

  def test_govcloud_virtual_cores
    region = @@ec2_pricing.get_region('us-gov-west-1')
    instance = region.get_ec2_instance_type('m3.large')
    assert instance.virtual_cores == 2
  end

  def test_govcloud_ebs
    region = @@ec2_pricing.get_region('us-gov-west-1')
    # next two prices are no longer provided by aws (May 09, 2016)
    assert region.ebs_price.standard_per_gb == 0.065
	assert region.ebs_price.standard_per_million_io == 0.065
    assert region.ebs_price.preferred_per_gb == 0.15
    assert region.ebs_price.preferred_per_iops == 0.078
    assert region.ebs_price.s3_snaps_per_gb == 0.066
    # next two prices were added by aws (May 09, 2016)
    assert region.ebs_price.ebs_optimized_hdd_per_gb == 0.054
    assert region.ebs_price.ebs_cold_hdd_per_gb == 0.03

  end

  def test_govcloud_new_reservation_types
    region = @@ec2_pricing.get_region('us-gov-west-1')
    instance = region.get_ec2_instance_type('r3.large')
    os = instance.get_operating_system(:linux)
    assert os.ondemand_price_per_hour == 0.2
    assert os.partialupfront_prepay_1_year == 617
    assert os.allupfront_prepay_1_year == 927
    assert os.partialupfront_prepay_3_year == 1177
    assert os.allupfront_prepay_3_year == 1838
    assert os.noupfront_effective_rate_1_year == 0.125
    assert os.partialupfront_effective_rate_1_year == 0.1074
    assert os.allupfront_effective_rate_1_year == 0.1058
    assert os.partialupfront_effective_rate_3_year == 0.0738
    assert os.allupfront_effective_rate_3_year == 0.0699
  end
end
