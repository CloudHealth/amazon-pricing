#!/usr/bin/env ruby

#--
# Amazon Web Services Pricing Ruby library
#
# Ruby Gem Name::  amazon-pricing
# Author::    Joe Kinsella (mailto:joe.kinsella@gmail.com)
# Copyright:: Copyright (c) 2011-2012 Sonian
# License::   Distributes under the same terms as Ruby
# Home::      http://github.com/sonian/amazon-pricing
#++

$: << File.expand_path(File.dirname(__FILE__))
require 'helper'
require 'test/unit'

class TestEc2InstanceTypes < Test::Unit::TestCase
  def test_cc8xlarge_issue
    pricing = AwsPricing::PriceList.new
    obj = pricing.get_instance_type('us-east', 'cc2.8xlarge')
    assert obj.api_name == 'cc2.8xlarge'
  end

  def test_name_lookup
    pricing = AwsPricing::PriceList.new
    pricing.regions.each do |region|
      assert_not_nil region.name

      region.instance_types.each do |instance|
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
    pricing = AwsPricing::PriceList.new
    region = pricing.get_region('us-east')
    assert region.instance_type_available?('m1.large')
  end

  def test_fetch_all_breakeven_months
    pricing = AwsPricing::PriceList.new
    pricing.regions.each do |region|
      region.instance_types.each do |instance|
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
    pricing = AwsPricing::PriceList.new
    region = pricing.get_region('us-east')
    instance = region.get_instance_type('m1.large')
    bem = instance.get_breakeven_month(:linux, :heavy, :year1)
    assert bem == 6
  end

  def test_memory
    # Validate instance types in specific regions are available
    pricing = AwsPricing::PriceList.new
    region = pricing.get_region('us-east')
    instance = region.get_instance_type('m1.large')
    assert instance.memory_in_mb == 7500
  end

  def test_non_standard_region_name
    pricing = AwsPricing::PriceList.new
    region = pricing.get_region('eu-west-1')
    instance = region.get_instance_type('m1.large')
    assert instance.memory_in_mb == 7500
  end

  def test_ebs
    pricing = AwsPricing::PriceList.new
    region = pricing.get_region('us-east')
    assert region.ebs_price.standard_per_gb == 0.10
    assert region.ebs_price.standard_per_million_io == 0.10
    assert region.ebs_price.preferred_per_gb == 0.125
    assert region.ebs_price.preferred_per_iops == 0.10
    assert region.ebs_price.s3_snaps_per_gb == 0.095
  end

  def test_ebs_not_null
    pricing = AwsPricing::PriceList.new
    pricing.regions.each do |region|
      # Everyone should have standard pricing
      assert_not_nil region.ebs_price.standard_per_gb
      assert_not_nil region.ebs_price.standard_per_million_io
      assert_not_nil region.ebs_price.s3_snaps_per_gb
    end
  end

  def test_virtual_cores
    pricing = AwsPricing::PriceList.new
    region = pricing.get_region('us-east')
    instance = region.get_instance_type('m1.large')
    assert instance.virtual_cores == 2
  end

end
