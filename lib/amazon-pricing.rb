require 'json'
require 'net/http'
require 'mechanize'

Dir[File.join(File.dirname(__FILE__), 'amazon-pricing/definitions/*.rb')].sort.each { |lib| require lib }

require 'amazon-pricing/aws-price-list'
require 'amazon-pricing/ec2-price-list'
require 'amazon-pricing/rds-price-list'
require 'amazon-pricing/dynamo-db-price-list'
