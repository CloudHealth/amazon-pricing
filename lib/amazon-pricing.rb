require 'json'
require 'net/http'

Dir[File.join(File.dirname(__FILE__), 'amazon-pricing/definitions/*.rb')].sort.each { |lib| require lib }

require 'amazon-pricing/common/ec2_common'

require 'amazon-pricing/aws-price-list'
require 'amazon-pricing/ec2-price-list'
require 'amazon-pricing/ec2-di-price-list'
require 'amazon-pricing/rds-price-list'
require 'amazon-pricing/dynamo-db-price-list'
