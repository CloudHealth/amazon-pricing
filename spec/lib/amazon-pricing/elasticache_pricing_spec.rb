require 'spec_helper'

describe AwsPricing::ElastiCachePriceList do
  before(:all) do
    @pricing = AwsPricing::ElastiCachePriceList.new
    @node_types = [:memcached]
  end
  
  describe 'new' do
    it 'ElastiCachePriceList.new should return the valid response' do
      @pricing.regions.each do |region|
        # Result have valid node name
        expect(@node_types).to include(region.elasticache_node_types.first.category_types.first.name)
        # values should not be nil
        region.elasticache_node_types.first.category_types.first.ondemand_price_per_hour.should_not be_nil
        # other prices per hour
        region.elasticache_node_types.first.category_types.first.partialupfront_prepay_1_year.should_not be_nil
        region.elasticache_node_types.first.category_types.first.partialupfront_prepay_3_year.should_not be_nil
        region.elasticache_node_types.first.category_types.first.partialupfront_price_per_hour_1_year.should_not be_nil
        region.elasticache_node_types.first.category_types.first.partialupfront_price_per_hour_3_year.should_not be_nil
      end
    end
  end

  describe '::get_api_name' do
    it "raises an UnknownTypeError on an unexpected instance type" do
      expect {
        AwsPricing::ElastiCacheNodeType::get_name 'IDK', 'MoreIDK'
      }.to raise_error(AwsPricing::UnknownTypeError)
    end
  end

  describe 'get_breakeven_months' do
    it "test_fetch_all_breakeven_months" do 
      @pricing.regions.each do |region|
        region.elasticache_node_types.each do |node|
          [:year1, :year3].each do |term|
            [:partialupfront].each do |res_type|
              [:memcached].each do |cache|
                node.get_breakeven_month(cache, res_type, term).should_not be_nil
              end
            end
          end
        end
      end
    end
  end
end
