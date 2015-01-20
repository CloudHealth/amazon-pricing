module AwsPricing
  class DynamoDBPriceList < PriceList

    THROUGHPUT_URL = "http://a0.awsstatic.com/pricing/1/dynamodb/pricing-data-throughput.min.js"
    STORAGE_URL = "http://a0.awsstatic.com/pricing/1/dynamodb/pricing-data-storage.min.js"
    RESERVED_CAPACITY_URL = "http://a0.awsstatic.com/pricing/1/dynamodb/pricing-reserved-capacity.min.js"
    DATA_TRANSFER_URL = "http://a0.awsstatic.com/pricing/1/dynamodb/pricing-data-transfer.min.js"

    def initialize
      super
    end

    def throughput_pricing
      @throughput_pricing ||= PriceList.fetch_url(THROUGHPUT_URL)
    end

    def storage_pricing
      @storage_pricing ||= PriceList.fetch_url(STORAGE_URL)
    end

    def reserved_capacity_pricing
      @reserved_capacity_pricing ||= PriceList.fetch_url(RESERVED_CAPACITY_URL)
    end

    def data_transfer_pricing
      @data_transfer_pricing ||= PriceList.fetch_url(DATA_TRANSFER_URL)
    end

  end
end
