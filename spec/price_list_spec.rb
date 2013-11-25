require 'amazon-pricing'
require 'spec_helper'

describe AwsPricing::PriceList do

# Need to update below based on 2013-07 changes
=begin
  describe "#get_ec2_on_demand_instance_pricing" do
    let(:price_list) {
      {
        'config' => {
          'regions' => [{
            'region' => 'us-east',
            'instanceTypes' => [{
              'type' => 'stdODI',
              'sizes' => [{
                'size' => 'sm',
                'valueColumns' => [
                  {'name' => 'linux', 'prices' => { 'USD' => '0.065' }},
                  {'name' => 'mswin', 'prices' => { 'USD' => '0.265' }}
                                  ]}]}]}]
        }
      }
    }

    before do
      AwsPricing::PriceList.any_instance.tap do |it|
        it.stub :get_ec2_reserved_instance_pricing
        it.stub :fetch_ec2_ebs_pricing
        it.stub :fetch_url => price_list
      end
    end
    
    it "doesn't break when amazon adds instance types" do
      newType = {'type' => 'quantumODI', 'sizes' => [{'size' => 'sm', 'valueColumns' => []}]}
      price_list['config']['regions'][0]['instanceTypes'] << newType

      expect {
        AwsPricing::PriceList.new
      }.to_not raise_error
    end
  end
=end
end