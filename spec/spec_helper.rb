#BROKEN IN TDDIUM: Dir.glob('spec/support/**/*.rb').sort.each {|f| require f}

require 'simplecov'
SimpleCov.start 'rails'

RSpec.configure do |c|
  c.filter_run_excluding broken: true
end

require 'amazon-pricing'
