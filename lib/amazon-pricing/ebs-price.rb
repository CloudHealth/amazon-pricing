#--
# Amazon Web Services Pricing Ruby library
#
# Ruby Gem Name::  amazon-pricing
# Author::    Joe Kinsella (mailto:joe.kinsella@gmail.com)
# Copyright:: Copyright (c) 2011-2013 CloudHealth
# License::   Distributes under the same terms as Ruby
# Home::      http://github.com/CloudHealth/amazon-pricing
#++
module AwsPricing

  class EbsPrice
    attr_accessor :standard_per_gb, :standard_per_million_io, :s3_snaps_per_gb,
      :preferred_per_gb, :preferred_per_iops,
      :ssd_per_gb, :ssd_per_iops

    def initialize(region)
      #@region = region
    end

    # e.g http://a0.awsstatic.com/pricing/1/ebs/pricing-ebs.min.js
    def update_from_json(json)
      json["types"].each do |t|
        case t["name"]
        when "Amazon EBS Magnetic volumes"
          @standard_per_gb = t["values"].select{|v| v["rate"] == "perGBmoProvStorage" }.first["prices"].values.first.to_f
          @standard_per_million_io = t["values"].select{|v| v["rate"] == "perMMIOreq" }.first["prices"].values.first.to_f
        when "Amazon EBS Provisioned IOPS (SSD) volumes"
          @preferred_per_gb = t["values"].select{|v| v["rate"] == "perGBmoProvStorage" }.first["prices"].values.first.to_f
          @preferred_per_iops = t["values"].select{|v| v["rate"] == "perPIOPSreq" }.first["prices"].values.first.to_f
        when "Amazon EBS General Purpose (SSD) volumes"
          @ssd_per_gb = t["values"].select{|v| v["rate"] == "perGBmoProvStorage" }.first["prices"].values.first.to_f
          #@ssd_per_iops = t["values"].select{|v| v["rate"] == "perPIOPSreq" }.first["prices"].values.first.to_f
        when "ebsSnapsToS3"
          @s3_snaps_per_gb = t["values"].select{|v| v["rate"] == "perGBmoDataStored" }.first["prices"].values.first.to_f
        end
      end
    end

  end
end
