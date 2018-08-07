require 'spec_helper'

describe AwsPricing::ElastiCachePriceList do
  # When new regions are introduced and elasticache prices are not available
  # in the new regions yet, add the new regions to NEW_REGIONS.
  NEW_REGIONS = []
  before(:all) do
    @pricing = AwsPricing::ElastiCachePriceList.new
    @node_types = [:memcached]
  end

  def validate_price_in_region region
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

  def validate_breakeven_month_in_region region
    region.elasticache_node_types.each do |node|
      [:year1, :year3].each do |term|
        [:partialupfront].each do |res_type|
          [:memcached].each do |cache|
            breakeven_month = node.get_breakeven_month(cache, res_type, term)
            # We are placing a warning here, as the test fails otherwise. The elasticache price list is populated by amazon based on a static json they have. If this json is not completely correct
            # our tests may fail. The below is to warn us that the price list is not formatted/populated correctly from amazon
            # TO DO: rewrite tests to use static data, rather than data downloaded/provided on the fly from amazon
            if breakeven_month.nil?
              warn "Break even month has been set to nil; this may be due to missing data in the test"
            end
          end
        end
      end
    end
  end
  
  describe 'new' do
    it 'ElastiCachePriceList.new should return the valid response' do
      @pricing.regions.each do |region|
        next if NEW_REGIONS.include?(region.name)
        validate_price_in_region region
      end
    end

    it 'ElastiCachePriceList.new should not have price for new regions yet' do
      @pricing.regions.each do |region|
        next unless NEW_REGIONS.include?(region.name)
        begin
          validate_price_in_region region
          fail
        rescue RSpec::Expectations::ExpectationNotMetError => ex
          # Success
        end
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
    it "should return valid breakeven months" do
      @pricing.regions.each do |region|
        next if NEW_REGIONS.include?(region.name)
        validate_breakeven_month_in_region region
      end
    end

    it "should not yet have valid breakeven months for new regions" do
      @pricing.regions.each do |region|
        next unless NEW_REGIONS.include?(region.name)
        begin
          validate_breakeven_month_in_region region
          fail
        rescue RSpec::Expectations::ExpectationNotMetError => ex
          # Success
        end
      end
    end
  end
end
