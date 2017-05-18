require 'amazon-pricing/definitions/instance-type'

module AwsPricing
  class Ec2DedicatedHostType < InstanceType

    def initialize(region, family_name)
      @category_types = {}
      @region = region
      @name = ''
      @api_name = family_name
    end

    def category_types
      @category_types
    end

    def region
      @region
    end

    def update_dh_pricing(operating_system, dhprice)
      os = get_category_type(operating_system)
      if os.nil?
        os = OperatingSystem.new(self, operating_system)
        @category_types[operating_system] = os
      end

      category = operating_system.to_s
      values = { category => dhprice }
      price = coerce_price(values[category])
      os.set_price_per_hour(:ondemand, nil, price)
    end

  end

end
