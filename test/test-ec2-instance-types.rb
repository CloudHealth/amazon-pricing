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

require File.dirname(__FILE__) + '/helper.rb'
require 'test/unit'

class TestEc2InstanceTypes < Test::Unit::TestCase
  def test_cc8xlarge_issue
    pricing = AwsPricing::PriceList.new
    obj = pricing.get_instance_type('us-east', :reserved, 'cc2.8xlarge', :medium)
    assert obj.api_name == 'cc2.8xlarge'
  end

  def test_name_lookup
    pricing = AwsPricing::PriceList.new
    pricing.regions.each do |region|
      assert_not_nil region.name
      region.ec2_on_demand_instance_types.each do |instance_type|
        assert_not_nil instance_type.api_name
        assert_not_nil instance_type.name
        assert instance_type.api_name != instance_type.name
      end
      region.ec2_reserved_instance_types(:light).each do |instance_type|
        assert_not_nil instance_type.api_name
        assert_not_nil instance_type.name
        assert instance_type.api_name != instance_type.name
      end
      region.ec2_reserved_instance_types(:medium).each do |instance_type|
        assert_not_nil instance_type.api_name
        assert_not_nil instance_type.name
        assert instance_type.api_name != instance_type.name
      end
      region.ec2_reserved_instance_types(:heavy).each do |instance_type|
        assert_not_nil instance_type.api_name
        assert_not_nil instance_type.name
        assert instance_type.api_name != instance_type.name
      end
    end
  end

  def test_unavailable
    # Validate instance types in specific regions are not available
    pricing = AwsPricing::PriceList.new
    region = pricing.get_region('apac-tokyo')
    assert !region.instance_type_available?(:on_demand, 'cc1.4xlarge')
  end

  def test_available
    # Validate instance types in specific regions are available
    pricing = AwsPricing::PriceList.new
    region = pricing.get_region('us-east')
    assert region.instance_type_available?(:on_demand, 'm1.large')
  end

  def test_memory
    # Validate instance types in specific regions are available
    pricing = AwsPricing::PriceList.new
    region = pricing.get_region('us-east')
    instance = region.get_instance_type(:on_demand, 'm1.large')
    assert instance.memory_in_mb == 7500
  end

  def test_non_standard_region_name
    pricing = AwsPricing::PriceList.new
    region = pricing.get_region('eu-west-1')
    instance = region.get_instance_type(:on_demand, 'm1.large')
    assert instance.memory_in_mb == 7500
  end

  def test_ebs
    pricing = AwsPricing::PriceList.new
    region = pricing.get_region('us-east')
    assert region.ebs_price.standard_per_gb == 0.10
    assert region.ebs_price.standard_per_million_io == 0.10
    assert region.ebs_price.preferred_per_gb == 0.125
    assert region.ebs_price.preferred_per_iops == 0.10
    assert region.ebs_price.s3_snaps_per_gb == 0.125
  end
end
