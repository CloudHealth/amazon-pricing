require 'amazon-pricing/instance-type'

describe AwsPricing::InstanceType do
  describe '::get_api_name' do
    it "raises an UnknownTypeError on an unexpected instance type" do
      expect {
        AwsPricing::InstanceType::get_name 'QuantumODI', 'huge'
      }.to raise_error(AwsPricing::UnknownTypeError)
    end
  end
end