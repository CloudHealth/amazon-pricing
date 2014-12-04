
require 'json'
require 'net/http'
require 'mechanize'

Dir[File.join(File.dirname(__FILE__), 'amazon-pricing/*.rb')].sort.each { |lib| require lib }

require 'aws-price-list'
require 'ec2-price-list'
require 'gov-cloud-price-list'
require 'rds-price-list'

require 'logger'
logger = Logger.new(STDERR)
logger.level = Logger::WARN

