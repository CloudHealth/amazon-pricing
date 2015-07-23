require 'amazon-pricing/definitions/instance-type'

module AwsPricing
  class ElastiCacheNodeType < InstanceType

    def initialize(region, api_name, name)
      @category_types = {}
      
      @region   = region
      @name     = name
      @api_name = api_name

      api_name_for_lookup = api_name.sub("cache.", "")
      
      @memory_in_mb  = InstanceType.get_memory(api_name)
      @virtual_cores = InstanceType.get_virtual_cores(api_name_for_lookup)
    end

    def available?(cache_type = :memcached, type_of_instance = :ondemand)
      cache = get_category_type(cache_type)
      return false if cache.nil?
      cache.available?(type_of_instance)
    end

    def update_pricing(cache_type, type_of_instance, json)
      cache = get_category_type(cache_type)
      if cache.nil?
        cache = Cache.new(self, cache_type)
        @category_types[cache_type] = cache
      end
      
      if type_of_instance == :ondemand
        values = ElastiCacheNodeType::get_values(json, cache_type)
        price = coerce_price(values[cache_type.to_s])
        cache.set_price_per_hour(type_of_instance, nil, price)
      else
        json['valueColumns'].each do |val|

          if val['prices']['USD'].empty?
            next
          end

          price = coerce_price(val['prices']['USD'])

          case val['name']
          when "yrTerm1"
            cache.set_prepay(type_of_instance, :year1, price)
          when "yrTerm3"
            cache.set_prepay(type_of_instance, :year3, price)
          when "yearTerm1Hourly"
            cache.set_price_per_hour(type_of_instance, :year1, price)
          when "yearTerm3Hourly"
            cache.set_price_per_hour(type_of_instance, :year3, price)
          end
        end
      end
    end

    protected

    def self.get_name(instance_type, api_name, is_reserved = false)
      api_name.sub!(" *", "")

      unless @@Name_Lookup.has_key? api_name
        raise UnknownTypeError, "Unknown instance type #{instance_type} #{api_name}", caller
      end

      name = @@Name_Lookup.has_key? api_name

      [api_name, name]
    end
                       
  end
end
