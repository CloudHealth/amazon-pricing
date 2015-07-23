module AwsPricing
  class ElastiCachePriceList < PriceList

    def initialize
      super
      get_elasticache_on_demand_node_pricing
      get_elasticache_reserved_node_pricing
    end

    protected

    # for now all engines have the save cost
    @@CACHE_TYPES = [:memcached]
    
    def get_elasticache_on_demand_node_pricing
      od_url = ELASTICACHE_BASE_URL + "pricing-standard-deployments-elasticache.min.js"
      od_legacy_url = ELASTICACHE_BASE_URL + "previous-generation/pricing-standard-deployments-elasticache.min.js"
      @@CACHE_TYPES.each do |type|
        fetch_on_demand_elasticache_node_pricing(od_url, type)

        # fetch again for legacy prices
        fetch_on_demand_elasticache_node_pricing(od_legacy_url, type)
      end
    end

    def get_elasticache_reserved_node_pricing
      rc_url = ELASTICACHE_BASE_URL + "pricing-elasticache-heavy-standard-deployments.min.js"
      rc_legacy_url =  ELASTICACHE_BASE_URL + "previous-generation/pricing-elasticache-heavy-standard-deployments.min.js"
      @@CACHE_TYPES.each do |type|
        fetch_reserved_elasticache_node_pricing(rc_url, type)

        # fetch again for legacy prices
        fetch_reserved_elasticache_node_pricing(rc_legacy_url, type)
      end
    end

    def fetch_on_demand_elasticache_node_pricing(url, cache_type)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = get_region(region_name)
        if region.nil?
          $stderr.puts "[fetch_elasticache_od_node_pricing] WARNING: unable to find region #{region_name}"
          next
        end # region.nil?

        reg['types'].each do |type|
          name = type['name']
          
          type['tiers'].each do |tier|
            begin
              api_name = tier['name']
              node_type = region.add_or_update_elasticache_node_type(api_name, name)
              node_type.update_pricing(cache_type, :ondemand, tier)
            rescue UnknownTypeError
              $stderr.puts "[fetch_on_demand_elasticache_node_pricing] WARNING: encountered #{$!.message}"
            end # begin
          end # do |tier|
        end # do |type|
      end # do |reg|
    end

    def fetch_reserved_elasticache_node_pricing(url, cache_type)
      res = PriceList.fetch_url(url)
      res['config']['regions'].each do |reg|
        region_name = reg['region']
        region = get_region(region_name)
        if region.nil?
          $stderr.puts "[fetch_elasticache_rc_node_pricing] WARNING: unable to find region #{region_name}"
          next
        end #region.nil?
        
        reg['instanceTypes'].each do |type|
          name = type['generation']
          type['tiers'].each do |tier|
            begin
              api_name = tier['size']
              node_type = region.add_or_update_elasticache_node_type(api_name, name)
              node_type.update_pricing(cache_type, :partialupfront, tier)
            rescue UnknownTypeError
              $stderr.puts "[fetch_reserved_rds_instance_pricing] WARNING: encountered #{$!.message}"
            end
          end # do |tier|
        end # do |type|
      end # do |reg|
    end
    
  end
end
