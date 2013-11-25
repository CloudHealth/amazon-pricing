#require 'amazon-pricing/instance-type'
#
# THIS TEST IS NO LONGER VALID
#describe AwsPricing::InstanceType do
#  describe '::get_values' do
#    it 'raises an UnknownTypeError on an unexpected instance type' do
#      expect {
#        AwsPricing::InstanceType::get_values 'QuantumODI', 'huge'
#      }.to raise_error(AwsPricing::UnknownTypeError)
#    end
#  end
#end