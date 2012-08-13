#--
# Amazon Web Services Pricing Ruby library
#
# Ruby Gem Name::  amazon-pricing
# Author::    Joe Kinsella (mailto:joe.kinsella@gmail.com)
# Copyright:: Copyright (c) 2011-2012 Sonian
# License::   Distributes under the same terms as Ruby
# Home::      http://github.com/sonian/amazon-pricing
#++
module AwsPricing

  class EbsPrice
    attr_reader :region, :standard_per_gb, :standard_per_million_io,
      :preferred_per_gb, :preferred_per_iops, :s3_snaps_per_gb

    def initialize(region, json)
      @region = region
      json["types"].each do |t|
        case t["name"]
        when "ebsVols"
          @standard_per_gb = t["values"].select{|v| v["rate"] == "perGBmoProvStorage" }.first["prices"].values.first.to_f
          @standard_per_million_io = t["values"].select{|v| v["rate"] == "perMMIOreq" }.first["prices"].values.first.to_f
        when "ebsPIOPSVols"
          @preferred_per_gb = t["values"].select{|v| v["rate"] == "perGBmoProvStorage" }.first["prices"].values.first.to_f
          @preferred_per_iops = t["values"].select{|v| v["rate"] == "perPIOPSreq" }.first["prices"].values.first.to_f
        when "ebsSnapsToS3"
          @s3_snaps_per_gb = t["values"].select{|v| v["rate"] == "perGBmoDataStored" }.first["prices"].values.first.to_f
        end
      end
    end

  end
end
