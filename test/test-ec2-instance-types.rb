#!/usr/bin/env ruby

#--
# Amazon Web Services Pricing Ruby library
#
# Ruby Gem Name::  aws-pricing
# Author::    Joe Kinsella (mailto:joe.kinsella@gmail.com)
# Copyright:: Copyright (c) 2011-2012 Sonian
# License::   Distributes under the same terms as Ruby
# Home::      http://github.com/sonian/aws-pricing
#++

require File.dirname(__FILE__) + '/helper.rb'
require 'test/unit'

class TestEc2InstanceTypes < Test::Unit::TestCase
  def test_name_lookup
    pricing = AwsPricing::PriceList.new
    pricing.regions.each do |region|
      assert_not_nil region.name
      region.ec2_on_demand_instance_types.each do |instance_type|
        assert_not_nil instance_type.api_name
        assert_not_nil instance_type.name
      end
      region.ec2_reserved_instance_types.each do |instance_type|
        assert_not_nil instance_type.api_name
        assert_not_nil instance_type.name
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

end
