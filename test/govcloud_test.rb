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
require 'test/unit'

class TestGovCloud < Test::Unit::TestCase
  class << self
    def startup
      #This is expensive, so only do once.
      @@ec2_pricing = AwsPricing::GovCloudEc2PriceList.new
    end
  end

  def test_cc8xlarge_issue
    obj = @@ec2_pricing.get_instance_type('us-gov-west', 'cc2.8xlarge')
    assert obj.api_name == 'cc2.8xlarge'
  end

  def test_memory
    # Validate instance types in specific regions are available
    region = @@ec2_pricing.get_region('us-gov-west')
    instance = region.get_ec2_instance_type('m1.large')
    assert instance.memory_in_mb == 7500
  end

  def test_virtual_cores
    region = @@ec2_pricing.get_region('us-gov-west')
    instance = region.get_ec2_instance_type('m1.large')
    assert instance.virtual_cores == 2
  end

end
