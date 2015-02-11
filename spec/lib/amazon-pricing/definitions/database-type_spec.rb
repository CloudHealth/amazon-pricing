require 'spec_helper'

describe 'AwsPricing::DatabaseType' do
  context 'Display Names' do
    ::AwsPricing::DatabaseType.class_variable_get(:@@ProductDescription).each_pair.each do |k, v|
      class_eval %*
        it "#{k} should be defined" do
          ::AwsPricing::DatabaseType.class_variable_get(:@@Database_Name_Lookup)['#{v}'].should_not eq(nil)
        end
      *
    end
  end
end