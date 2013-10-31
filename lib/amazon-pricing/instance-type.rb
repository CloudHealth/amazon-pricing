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

  class UnknownTypeError < NameError
  end

  class InstanceType
    attr_accessor :name, :api_name, :memory_in_mb, :disk_in_mb, :platform, :compute_units, :virtual_cores
    
    def initialize(region, api_name, name)
      @category_types = {}

      @region = region
      @name = name
      @api_name = api_name

      @memory_in_mb = @@Memory_Lookup[@api_name]
      @disk_in_mb = @@Disk_Lookup[@api_name]
      @platform = @@Platform_Lookup[@api_name]
      @compute_units = @@Compute_Units_Lookup[@api_name]
      @virtual_cores = @@Virtual_Cores_Lookup[@api_name]
    end

    def category_types
      @category_types.values
    end

    def get_category_type(name)
      @category_types[name]
    end

    def getprint(name)
      @category_types[name]
    end

    # Returns whether an instance_type is available. 
    # category_type = :mysql, :oracle, :sqlserver, :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def available?(type_of_instance = :ondemand, category_type = :linux)
      cat = get_category_type(category_type)
      return false if cat.nil?
      cat.available?(type_of_instance)
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def price_per_hour(category_type, type_of_instance, term = nil)
      cat = get_category_type(category_type) 
      cat.price_per_hour(type_of_instance, term) unless cat.nil?
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def prepay(category_type, type_of_instance, term = nil)
      cat = get_category_type(category_type)
      cat.prepay(type_of_instance, term) unless cat.nil?
    end

    # category_type = :mysql, :oracle, :sqlserver
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def update_pricing(category_type, type_of_instance, json)
      cat = get_category_type(category_type)
      if cat.nil?
        cat = CategoryType.new(self, category_type)
        @category_types[category_type] = cat
      end

      if type_of_instance == :ondemand
        values = InstanceType::get_values(json,category_type)
        price = coerce_price(values[category_type.to_s])
        cat.set_price_per_hour(type_of_instance, nil, price)
      else
        json['valueColumns'].each do |val|
          price = coerce_price(val['prices']['USD'])
          case val["name"]
          when "yrTerm1"
            cat.set_prepay(type_of_instance, :year1, price)
          when "yrTerm3"
            cat.set_prepay(type_of_instance, :year3, price)
          when "yrTerm1Hourly"
            cat.set_price_per_hour(type_of_instance, :year1, price)
          when "yrTerm3Hourly"
            cat.set_price_per_hour(type_of_instance, :year3, price)

          when "yearTerm1Hourly"
            cat.set_price_per_hour(type_of_instance, :year1, price)
          when "yearTerm3Hourly"
            cat.set_price_per_hour(type_of_instance, :year3, price)     
          end
        end
      end
    end

    # type_of_instance = :ondemand, :light, :medium, :heavy
    # term = :year_1, :year_3, nil
    def get_breakeven_month(category_type, type_of_instance, term)
      cat = get_category_type(category_type)
      cat.get_breakeven_month(type_of_instance, term)
    end

    protected

    def coerce_price(price)
      return nil if price.nil? || price == "N/A"
      price.to_f
    end

    # Returns [api_name, name]
    def self.get_name(instance_type, size, is_reserved = false)
      lookup = @@Api_Name_Lookup
      lookup = @@Api_Name_Lookup_Reserved if is_reserved

      # Let's handle new instances more gracefully
      unless lookup.has_key? instance_type
        raise UnknownTypeError, "Unknown instance type #{instance_type}", caller
      else
        api_name = lookup[instance_type][size]
      end

      lookup = @@Name_Lookup
      lookup = @@Name_Lookup_Reserved if is_reserved
      name = lookup[instance_type][size]

      [api_name, name]
    end

    def self.get_values(json, category_type)
      values = {}
      unless json['valueColumns'].nil?
        json['valueColumns'].each do |val|
          values[val['name']] = val['prices']['USD']
        end
      else
        values[category_type.to_s] = json['prices']['USD']
      end       
      values
    end

    @@Api_Name_Lookup = {
      'stdODI' => {'sm' => 'm1.small', 'med' => 'm1.medium', 'lg' => 'm1.large', 'xl' => 'm1.xlarge'},
      'hiMemODI' => {'xl' => 'm2.xlarge', 'xxl' => 'm2.2xlarge', 'xxxxl' => 'm2.4xlarge'},
      'hiCPUODI' => {'med' => 'c1.medium', 'xl' => 'c1.xlarge'},
      'hiIoODI' => {'xxxxl' => 'hi1.4xlarge'},
      'clusterGPUI' => {'xxxxl' => 'cg1.4xlarge'},
      'clusterComputeI' => {'xxxxl' => 'cc1.4xlarge','xxxxxxxxl' => 'cc2.8xlarge'},
      'uODI' => {'u' => 't1.micro'},
      'secgenstdODI' => {'xl' => 'm3.xlarge', 'xxl' => 'm3.2xlarge'},
      'clusterHiMemODI' => {'xxxxxxxxl' => 'cr1.8xlarge'},
      'hiStoreODI' => {'xxxxxxxxl' => 'hs1.8xlarge'},

      # RDS On-Demand Instances
      
      #Mysql
      'udbInstClass' => {'uDBInst'=>'udb.t1.micro'},
      'dbInstClass'=> {'uDBInst' => 't1.micro', 'smDBInst' => 'm1.small', 'medDBInst' => 'm1.medium', 'lgDBInst' => 'm1.large', 'xlDBInst' => 'm1.xlarge'},
      'hiMemDBInstClass'=> {'xlDBInst' => 'm2.xlarge', 'xxlDBInst' => 'm2.2xlarge', 'xxxxDBInst' => 'm2.4xlarge'},
      'clusterHiMemDB' => {'xxxxxxxxl' => 'm2.8xlarge'},
      'multiclusterHiMemDB' => {'xxxxxxxxl' => 'mul.m2.8xlarge'},
      'multiAZDBInstClass'=> {'uDBInst' => 'mul.t1.micro', 'smDBInst' => 'mul.m1.small', 'medDBInst' => 'mul.m1.medium', 'lgDBInst' => 'mul.m1.large', 'xlDBInst' => 'mul.m1.xlarge'},
      'multiAZHiMemInstClass'=> {'xlDBInst' => 'mul.m2.xlarge', 'xxlDBInst' => 'mul.m2.2xlarge', 'xxxxDBInst' => 'mul.m2.4xlarge'},
      #Oracle
      'li-standard-dbInstClass'=> {'uDBInst' => 'li.standard.t1.micro', 'smDBInst' => 'li.standard.m1.small', 'medDBInst' => 'li.standard.m1.medium', 'lgDBInst' => 'li.standard.m1.large', 'xlDBInst' => 'li.standard.m1.xlarge'},
      'li-standard-hiMemDBInstClass'=> {'xlDBInst' => 'li.standard.m2.xlarge', 'xxlDBInst' => 'li.standard.m2.2xlarge', 'xxxxDBInst' => 'li.standard.m2.4xlarge'},
      'li-multiAZ-dbInstClass'=> {'uDBInst' => 'li.multiAZ.t1.micro', 'smDBInst' => 'li.multiAZ.m1.small', 'medDBInst' => 'li.multiAZ.m1.medium', 'lgDBInst' => 'li.multiAZ.m1.large', 'xlDBInst' => 'li.multiAZ.m1.xlarge'},
      'li-multiAZ-hiMemDBInstClass'=> {'xlDBInst' => 'li.multiAZ.m2.xlarge', 'xxlDBInst' => 'li.multiAZ.m2.2xlarge', 'xxxxDBInst' => 'li.multiAZ.m2.4xlarge'},
      'byol-standard-dbInstClass'=> {'uDBInst' => 'byol.standard.t1.micro', 'smDBInst' => 'byol.standard.m1.small', 'medDBInst' => 'byol.standard.m1.medium', 'lgDBInst' => 'byol.standard.m1.large', 'xlDBInst' => 'byol.standard.m1.xlarge'},
      'byol-standard-hiMemDBInstClass'=> {'xlDBInst' => 'byol.standard.m2.xlarge', 'xxlDBInst' => 'byol.standard.m2.2xlarge', 'xxxxDBInst' => 'byol.standard.m2.4xlarge'},
      'byol-multiAZ-multiAZDBInstClass'=> {'uDBInst' => 'byol.multiAZ.t1.micro', 'smDBInst' => 'byol.multiAZ.m1.small', 'medDBInst' => 'byol.multiAZ.m1.medium', 'lgDBInst' => 'byol.multiAZ.m1.large', 'xlDBInst' => 'byol.multiAZ.m1.xlarge'},
      'byol-multiAZ-multiAZHiMemInstClass'=> {'xlDBInst' => 'byol.multiAZ.m2.xlarge', 'xxlDBInst' => 'byol.multiAZ.m2.2xlarge', 'xxxxDBInst' => 'byol.multiAZ.m2.4xlarge'},
      #Sqlserver
      'li-ex-udbInstClass' => {'uDBInst'=>'li.ex.t1.micro'},
      'li-ex-dbInstClass'=> {'uDBInst' => 'li.ex.t1.micro', 'smDBInst' => 'li.ex.m1.small'},
      'li-web-dbInstClass'=> {'uDBInst' => 'li.web.t1.micro', 'smDBInst' => 'li.web.m1.small', 'medDBInst' => 'li.web.m1.medium', 'lgDBInst' => 'li.web.m1.large', 'xlDBInst' => 'li.web.m1.xlarge'},
      'li-web-hiMemDBInstClass'=> {'xlDBInst' => 'li.web.m2.xlarge', 'xxlDBInst' => 'li.web.m2.2xlarge', 'xxxxDBInst' => 'li.web.m2.4xlarge'},
      'li-se-dbInstClass'=> {'uDBInst' => 'li.se.t1.micro', 'smDBInst' => 'li.se.m1.small', 'medDBInst' => 'li.se.m1.medium', 'lgDBInst' => 'li.se.m1.large', 'xlDBInst' => 'li.se.m1.xlarge'},
      'li-se-hiMemDBInstClass'=> {'xlDBInst' => 'li.se.m2.xlarge', 'xxlDBInst' => 'li.se.m2.2xlarge', 'xxxxDBInst' => 'li.se.m2.4xlarge'},
      'byol-dbInstClass'=> {'uDBInst' => 'byol.t1.micro', 'smDBInst' => 'byol.m1.small', 'medDBInst' => 'byol.m1.medium', 'lgDBInst' => 'byol.m1.large', 'xlDBInst' => 'byol.m1.xlarge'},
      'byol-hiMemDBInstClass'=> {'xlDBInst' => 'byol.m2.xlarge', 'xxlDBInst' => 'byol.m2.2xlarge', 'xxxxDBInst' => 'byol.m2.4xlarge'}
    }
    @@Name_Lookup = {
      'stdODI' => {'sm' => 'Standard Small', 'med' => 'Standard Medium', 'lg' => 'Standard Large', 'xl' => 'Standard Extra Large'},
      'hiMemODI' => {'xl' => 'Hi-Memory Extra Large', 'xxl' => 'Hi-Memory Double Extra Large', 'xxxxl' => 'Hi-Memory Quadruple Extra Large'},
      'hiCPUODI' => {'med' => 'High-CPU Medium', 'xl' => 'High-CPU Extra Large'},
      'hiIoODI' => {'xxxxl' => 'High I/O Quadruple Extra Large'},
      'clusterGPUI' => {'xxxxl' => 'Cluster GPU Quadruple Extra Large'},
      'clusterComputeI' => {'xxxxl' => 'Cluster Compute Quadruple Extra Large', 'xxxxxxxxl' => 'Cluster Compute Eight Extra Large'},
      'uODI' => {'u' => 'Micro'},
      'secgenstdODI' => {'xl' => 'M3 Extra Large Instance', 'xxl' => 'M3 Double Extra Large Instance'},
      'clusterHiMemODI' => {'xxxxxxxxl' => 'High-Memory Cluster Eight Extra Large'},
      'hiStoreODI' => {'xxxxxxxxl' => 'High-Storage Eight Extra Large'},

      #
      # RDS On-Demand Instances
      #
      #Mysql
      'udbInstClass' => {'uDBInst'=>'Standard Micro'},
      'dbInstClass'=> {'uDBInst' => 'Standard Micro', 'smDBInst' => 'Standard Small', 'medDBInst' => 'Standard Medium', 'lgDBInst' => 'Standard Large', 'xlDBInst' => 'Standard Extra Large'},
      'hiMemDBInstClass'=> {'xlDBInst' => 'Standard High-Memory Extra Large', 'xxlDBInst' => 'Standard High-Memory Double Extra Large', 'xxxxDBInst' => 'Standard High-Memory Quadruple Extra Large'},
      'clusterHiMemDB' => {'xxxxxxxxl' => 'Standard High-Memory Cluster Eight Extra Large'},
      'multiclusterHiMemDB' => {'xxxxxxxxl' => 'Multi-AZ High-Memory Cluster Eight Extra Large'},
      'multiAZDBInstClass'=> {'uDBInst' => 'Multi-AZ Micro', 'smDBInst' => 'Multi-AZ Small', 'medDBInst' => 'Multi-AZ Medium', 'lgDBInst' => 'Multi-AZ Large', 'xlDBInst' => 'Multi-AZ Extra Large'},
      'multiAZHiMemInstClass'=> {'xlDBInst' => 'Multi-AZ High-Memory Extra Large', 'xxlDBInst' => 'Multi-AZ High-Memory Double Extra Large', 'xxxxDBInst' => 'Multi-AZ High-Memory Quadruple Extra Large'},
       #Oracle
      'li-standard-dbInstClass'=> {'uDBInst' => 'Li-Standard Micro', 'smDBInst' => 'Li-Standard Small', 'medDBInst' => 'Li-Standard Medium', 'lgDBInst' => 'Li-Standard Large', 'xlDBInst' => 'Li-Standard Extra Large'},
      'li-standard-hiMemDBInstClass'=> {'xlDBInst' => 'Li-Standard High-Memory Extra Large', 'xxlDBInst' => 'Li-Standard High-Memory Double Extra Large', 'xxxxDBInst' => 'Li-Standard High-Memory Quadruple Extra Large'},
      'li-multiAZ-dbInstClass'=> {'uDBInst' => 'Li-Multi-AZ Micro', 'smDBInst' => 'Li-Multi-AZ Small', 'medDBInst' => 'Li-Multi-AZ Medium', 'lgDBInst' => 'Li-Multi-AZ Large', 'xlDBInst' => 'Li-Multi-AZ Extra Large'},
      'li-multiAZ-hiMemDBInstClass'=> {'xlDBInst' => 'Li-Multi-AZ High-Memory Extra Large', 'xxlDBInst' => 'Li-Multi-AZ High-Memory Double Extra Large', 'xxxxDBInst' => 'Li-Multi-AZ High-Memory Quadruple Extra Large'},
      'byol-standard-dbInstClass'=> {'uDBInst' => 'Byol-Standard Micro', 'smDBInst' => 'Byol-Standard Small', 'medDBInst' => 'Byol-Standard Medium', 'lgDBInst' => 'Byol-Standard Large', 'xlDBInst' => 'Byol-Standard Extra Large'},
      'byol-standard-hiMemDBInstClass'=> {'xlDBInst' => 'Byol-Standard High-Memory Extra Large', 'xxlDBInst' => 'Byol-Standard High-Memory Double Extra Large', 'xxxxDBInst' => 'Byol-Standard High-Memory Quadruple Extra Large'},
      'byol-multiAZ-multiAZDBInstClass'=> {'uDBInst' => 'Byol-Multi-AZ Micro', 'smDBInst' => 'Byol-Multi-AZ Small', 'medDBInst' => 'Byol-Multi-AZ Medium', 'lgDBInst' => 'Byol-Multi-AZ Large', 'xlDBInst' => 'Byol-Multi-AZ Extra Large'},
      'byol-multiAZ-multiAZHiMemInstClass'=> {'xlDBInst' => 'Byol-Multi-AZ High-Memory Extra Large', 'xxlDBInst' => 'Byol-Multi-AZ High-Memory Double Extra Large', 'xxxxDBInst' => 'Byol-Multi-AZ High-Memory Quadruple Extra Large'},
       #Sqlserver
      'li-ex-udbInstClass' => {'uDBInst'=>'Li-Express Micro'},
      'li-ex-dbInstClass'=> {'uDBInst' => 'Li-Express Micro', 'smDBInst' => 'Li-Express Small'},
      'li-web-dbInstClass'=> {'uDBInst' => 'Li-Web Micro', 'smDBInst' => 'Li-Web Small', 'medDBInst' => 'Li-Web Medium', 'lgDBInst' => 'Li-Web Large', 'xlDBInst' => 'Li-Web Extra Large'},
      'li-web-hiMemDBInstClass'=> {'xlDBInst' => 'Li-Web High-Memory Extra Large', 'xxlDBInst' => 'Li-Web High-Memory Double Extra Large', 'xxxxDBInst' => 'Li-Web High-Memory Quadruple Extra Large'},
      'li-se-dbInstClass'=> {'uDBInst' => 'Li-Se Micro', 'smDBInst' => 'Li-Se Small', 'medDBInst' => 'Li-Se Medium', 'lgDBInst' => 'Li-Se Large', 'xlDBInst' => 'Li-Se Extra Large'},
      'li-se-hiMemDBInstClass'=> {'xlDBInst' => 'Li-Se High-Memory Extra Large', 'xxlDBInst' => 'Li-Se High-Memory Double Extra Large', 'xxxxDBInst' => 'Li-Se High-Memory Quadruple Extra Large'},
      'byol-dbInstClass'=> {'uDBInst' => 'Byol Micro', 'smDBInst' => 'Byol Small', 'medDBInst' => 'Byol Medium', 'lgDBInst' => 'Byol Large', 'xlDBInst' => 'Byol Extra Large'},
      'byol-hiMemDBInstClass'=> {'xlDBInst' => 'Byol High-Memory Extra Large', 'xxlDBInst' => 'Byol High-Memory Double Extra Large', 'xxxxDBInst' => 'Byol High-Memory Quadruple Extra Large'}

    }
    
    @@Api_Name_Lookup_Reserved = {
      'stdResI' => {'sm' => 'm1.small', 'med' => 'm1.medium', 'lg' => 'm1.large', 'xl' => 'm1.xlarge'},
      'hiMemResI' => {'xl' => 'm2.xlarge', 'xxl' => 'm2.2xlarge', 'xxxxl' => 'm2.4xlarge'},
      'hiCPUResI' => {'med' => 'c1.medium', 'xl' => 'c1.xlarge'},
      'clusterGPUResI' => {'xxxxl' => 'cg1.4xlarge'},
      'clusterCompResI' => {'xxxxl' => 'cc1.4xlarge', 'xxxxxxxxl' => 'cc2.8xlarge'},
      'uResI' => {'u' => 't1.micro'},
      'hiIoResI' => {'xxxxl' => 'hi1.4xlarge'},
      'secgenstdResI' => {'xl' => 'm3.xlarge', 'xxl' => 'm3.2xlarge'},
      'clusterHiMemResI' => {'xxxxxxxxl' => 'cr1.8xlarge'},
      'hiStoreResI' => {'xxxxxxxxl' => 'hs1.8xlarge'},
      
      #
      # RDS Reserved Instances
      #
      #Mysql
      'stdDeployRes' => {'u' => 't1.micro', 'micro' => 't1.micro', 'sm' => 'm1.small', 'med' => 'm1.medium', 'lg' => 'm1.large', 'xl' => 'm1.xlarge', 'xlHiMem' => 'm2.xlarge', 'xxlHiMem' => 'm2.2xlarge', 'xxxxlHiMem' => 'm2.4xlarge', 'xxxxxxxxl' => 'm2.8xlarge'},
      'multiAZdeployRes' => {'u' => 'mul.t1.micro', 'micro' => 'mul.t1.micro', 'sm' => 'mul.m1.small', 'med' => 'mul.m1.medium', 'lg' => 'mul.m1.large', 'xl' => 'mul.m1.xlarge', 'xlHiMem' => 'mul.m2.xlarge', 'xxlHiMem' => 'mul.m2.2xlarge', 'xxxxlHiMem' => 'mul.m2.4xlarge', 'xxxxxxxxl' => 'mul.m2.8xlarge'},
      #Oracle
      'li-stdDeployRes' => {'u' => 'li.standard.t1.micro', 'micro' => 'li.standard.t1.micro', 'sm' => 'li.standard.m1.small', 'med' => 'li.standard.m1.medium', 'lg' => 'li.standard.m1.large', 'xl' => 'li.standard.m1.xlarge', 'xlHiMem' => 'li.standard.m2.xlarge', 'xxlHiMem' => 'li.standard.m2.2xlarge', 'xxxxlHiMem' => 'li.standard.m2.4xlarge', 'xxxxxxxxl' => 'li.standard.m2.8xlarge'},
      'li-multiAZdeployRes' => {'u' => 'li.multiAZ.t1.micro', 'micro' => 'li.multiAZ.t1.micro', 'sm' => 'li.multiAZ.m1.small', 'med' => 'li.multiAZ.m1.medium', 'lg' => 'li.multiAZ.m1.large', 'xl' => 'li.multiAZ.m1.xlarge', 'xlHiMem' => 'li.multiAZ.m2.xlarge', 'xxlHiMem' => 'li.multiAZ.m2.2xlarge', 'xxxxlHiMem' => 'li.multiAZ.m2.4xlarge', 'xxxxxxxxl' => 'li.multiAZ.m2.8xlarge'},
      'byol-stdDeployRes' => {'u' => 'byol.standard.t1.micro', 'micro' => 'byol.standard.t1.micro', 'sm' => 'byol.standard.m1.small', 'med' => 'byol.standard.m1.medium', 'lg' => 'byol.standard.m1.large', 'xl' => 'byol.standard.m1.xlarge', 'xlHiMem' => 'byol.standard.m2.xlarge', 'xxlHiMem' => 'byol.standard.m2.2xlarge', 'xxxxlHiMem' => 'byol.standard.m2.4xlarge', 'xxxxxxxxl' => 'byol.standard.m2.8xlarge'},
      'byol-multiAZdeployRes' => {'u' => 'byol.multiAZ.t1.micro', 'micro' => 'byol.multiAZ.t1.micro', 'sm' => 'byol.multiAZ.m1.small', 'med' => 'byol.multiAZ.m1.medium', 'lg' => 'byol.multiAZ.m1.large', 'xl' => 'byol.multiAZ.m1.xlarge', 'xlHiMem' => 'byol.multiAZ.m2.xlarge', 'xxlHiMem' => 'byol.multiAZ.m2.2xlarge', 'xxxxlHiMem' => 'byol.multiAZ.m2.4xlarge', 'xxxxxxxxl' => 'byol.multiAZ.m2.8xlarge'},
      #Sqlserver
      'li-ex-stdDeployRes' => {'u' => 'li.ex.t1.micro', 'micro' => 'li.ex.t1.micro', 'sm' => 'li.ex.m1.small'},
      'li-web-stdDeployRes' => {'u' => 'li.web.t1.micro', 'micro' => 'li.web.t1.micro', 'sm' => 'li.web.m1.small', 'med' => 'li.web.m1.medium', 'lg' => 'li.web.m1.large', 'xl' => 'li.web.m1.xlarge', 'xlHiMem' => 'li.web.m2.xlarge', 'xxlHiMem' => 'li.web.m2.2xlarge', 'xxxxlHiMem' => 'li.web.m2.4xlarge', 'xxxxxxxxl' => 'li.web.m2.8xlarge'},
      'li-se-stdDeployRes' => {'u' => 'li.se.t1.micro', 'micro' => 'li.se.t1.micro', 'sm' => 'li.se.m1.small', 'med' => 'li.se.m1.medium', 'lg' => 'li.se.m1.large', 'xl' => 'li.se.m1.xlarge', 'xlHiMem' => 'li.se.m2.xlarge', 'xxlHiMem' => 'li.se.m2.2xlarge', 'xxxxlHiMem' => 'li.se.m2.4xlarge', 'xxxxxxxxl' => 'li.se.m2.8xlarge'},
      'sql-byol-stdDeployRes' => {'u' => 'byol.t1.micro', 'micro' => 'byol.t1.micro', 'sm' => 'byol.m1.small', 'med' => 'byol.m1.medium', 'lg' => 'byol.m1.large', 'xl' => 'byol.m1.xlarge', 'xlHiMem' => 'byol.m2.xlarge', 'xxlHiMem' => 'byol.m2.2xlarge', 'xxxxlHiMem' => 'byol.m2.4xlarge', 'xxxxxxxxl' => 'byol.m2.8xlarge'}
    }

    @@Name_Lookup_Reserved = {
      'stdResI' => {'sm' => 'Standard Small', 'med' => 'Standard Medium', 'lg' => 'Standard Large', 'xl' => 'Standard Extra Large'},
      'hiMemResI' => {'xl' => 'Hi-Memory Extra Large', 'xxl' => 'Hi-Memory Double Extra Large', 'xxxxl' => 'Hi-Memory Quadruple Extra Large'},
      'hiCPUResI' => {'med' => 'High-CPU Medium', 'xl' => 'High-CPU Extra Large'},
      'clusterGPUResI' => {'xxxxl' => 'Cluster GPU Quadruple Extra Large'},
      'clusterCompResI' => {'xxxxl' => 'Cluster Compute Quadruple Extra Large', 'xxxxxxxxl' => 'Cluster Compute Eight Extra Large'},
      'uResI' => {'u' => 'Micro'},
      'hiIoResI' => {'xxxxl' => 'High I/O Quadruple Extra Large Instance'},
      'secgenstdResI' => {'xl' => 'M3 Extra Large Instance', 'xxl' => 'M3 Double Extra Large Instance'},
      'clusterHiMemResI' => {'xxxxxxxxl' => 'High-Memory Cluster Eight Extra Large'},
      'hiStoreResI' => {'xxxxxxxxl' => 'High-Storage Eight Extra Large'},

      #
      # RDS Reserved Instances
      #
      #mysql
      'stdDeployRes' => {'u' => 'Standard Micro', 'micro' => 'Standard Micro', 'sm' => 'Standard Small', 'med' => 'Standard Medium', 'lg' => 'Standard Large', 'xl' => 'Standard Extra Large', 'xlHiMem' => 'Standard Extra Large High-Memory', 'xxlHiMem' => 'Standard Double Extra Large High-Memory', 'xxxxlHiMem' => 'Standard Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Standard Eight Extra Large'}  ,
      'multiAZdeployRes' => {'u' => 'Multi-AZ Micro', 'micro' => 'Multi-AZ Micro', 'sm' => 'Multi-AZ Small', 'med' => 'Multi-AZ Medium', 'lg' => 'Multi-AZ Large', 'xl' => 'Multi-AZ Extra Large', 'xlHiMem' => 'Multi-AZ Extra Large High-Memory', 'xxlHiMem' => 'Multi-AZ Double Extra Large High-Memory', 'xxxxlHiMem' => 'Multi-AZ Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Multi-AZ Eight Extra Large'},  
      #Oracle
      'li-stdDeployRes' => {'u' => 'Li-Standard Micro', 'micro' => 'Li-Standard Micro', 'sm' => 'Li-Standard Small', 'med' => 'Li-Standard Medium', 'lg' => 'Li-Standard Large', 'xl' => 'Li-Standard Extra Large', 'xlHiMem' => 'Li-Standard Extra Large High-Memory', 'xxlHiMem' => 'Li-Standard Double Extra Large High-Memory', 'xxxxlHiMem' => 'Li-Standard Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Li-Standard Eight Extra Large'}  ,
      'li-multiAZdeployRes' => {'u' => 'Li-Multi-AZ Micro', 'micro' => 'Li-Multi-AZ Micro', 'sm' => 'Li-Multi-AZ Small', 'med' => 'Li-Multi-AZ Medium', 'lg' => 'Li-Multi-AZ Large', 'xl' => 'Li-Multi-AZ Extra Large', 'xlHiMem' => 'Li-Multi-AZ Extra Large High-Memory', 'xxlHiMem' => 'Li-Multi-AZ Double Extra Large High-Memory', 'xxxxlHiMem' => 'Li-Multi-AZ Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Li-Multi-AZ Eight Extra Large'},  
      'byol-stdDeployRes' => {'u' => 'Byol-Standard Micro', 'micro' => 'Byol-Standard Micro', 'sm' => 'Byol-Standard Small', 'med' => 'Byol-Standard Medium', 'lg' => 'Byol-Standard Large', 'xl' => 'Byol-Standard Extra Large', 'xlHiMem' => 'Byol-Standard Extra Large High-Memory', 'xxlHiMem' => 'Byol-Standard Double Extra Large High-Memory', 'xxxxlHiMem' => 'Byol-Standard Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Byol-Standard Eight Extra Large'},
      'byol-multiAZdeployRes' => {'u' => 'Byol-Multi-AZ Micro', 'micro' => 'Byol-Multi-AZ Micro', 'sm' => 'Byol-Multi-AZ Small', 'med' => 'Byol-Multi-AZ Medium', 'lg' => 'Byol-Multi-AZ Large', 'xl' => 'Byol-Multi-AZ Extra Large', 'xlHiMem' => 'Byol-Multi-AZ Extra Large High-Memory', 'xxlHiMem' => 'Byol-Multi-AZ Double Extra Large High-Memory', 'xxxxlHiMem' => 'Byol-Multi-AZ Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Byol-Multi-AZ Eight Extra Large'},  
      #Sqlserver
      'li-ex-stdDeployRes' => {'u' => 'Li-Express Micro', 'micro' => 'Li-Express Micro', 'sm' => 'Li-Express Small', 'med' => 'Li-Express Medium', 'lg' => 'Li-Express Large', 'xl' => 'Li-Express Extra Large', 'xlHiMem' => 'Li-Express Extra Large High-Memory', 'xxlHiMem' => 'Li-Express Double Extra Large High-Memory', 'xxxxlHiMem' => 'Li-Express Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Li-Express Eight Extra Large'},
      'li-web-stdDeployRes' => {'u' => 'Li-Web Micro', 'micro' => 'Li-Web Micro', 'sm' => 'Li-Web Small', 'med' => 'Li-Web Medium', 'lg' => 'Li-Web Large', 'xl' => 'Li-Web Extra Large', 'xlHiMem' => 'Li-Web Extra Large High-Memory', 'xxlHiMem' => 'Li-Web Double Extra Large High-Memory', 'xxxxlHiMem' => 'Li-Web Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Li-Web Eight Extra Large'},
      'li-se-stdDeployRes' => {'u' => 'Li-Se Micro', 'micro' => 'Li-Se Micro', 'sm' => 'Li-Se Small', 'med' => 'Li-Se Medium', 'lg' => 'Li-Se Large', 'xl' => 'Li-Se Extra Large', 'xlHiMem' => 'Li-Se Extra Large High-Memory', 'xxlHiMem' => 'Li-Se Double Extra Large High-Memory', 'xxxxlHiMem' => 'Li-Se Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Li-Se Eight Extra Large'},
      'sql-byol-stdDeployRes' => {'u' => 'Byol Micro', 'micro' => 'Byol Micro', 'sm' => 'Byol Small', 'med' => 'Byol Medium', 'lg' => 'Byol Large', 'xl' => 'Byol Extra Large', 'xlHiMem' => 'Byol Extra Large High-Memory', 'xxlHiMem' => 'Byol Double Extra Large High-Memory', 'xxxxlHiMem' => 'Byol Quadruple Extra Large High-Memory', 'xxxxxxxxl' => 'Byol Eight Extra Large'}
    }

    @@Memory_Lookup = {
      'm1.small' => 1700, 'm1.medium' => 3750, 'm1.large' => 7500, 'm1.xlarge' => 15000,
      'm2.xlarge' => 17100, 'm2.2xlarge' => 34200, 'm2.4xlarge' => 68400, 'm2.8xlarge' => 136800,
      'm3.xlarge' => 15000, 'm3.2xlarge' => 30000,
      'c1.medium' => 1700, 'c1.xlarge' => 7000,
      'hi1.4xlarge' => 60500,
      'cg1.4xlarge' => 22000,
      'cc1.4xlarge' => 23000, 'cc2.8xlarge' => 60500,
      't1.micro' => 1700,
      'm3.xlarge' => 15000, 'm3.xlarge' => 30000,
      'cr1.8xlarge' => 244000,
      'hs1.8xlarge' => 117000,
    }
    @@Disk_Lookup = {
      'm1.small' => 160, 'm1.medium' => 410, 'm1.large' =>850, 'm1.xlarge' => 1690,
      'm2.xlarge' => 420, 'm2.2xlarge' => 850, 'm2.4xlarge' => 1690, 'm2.8xlarge' => 000,
      'm3.xlarge' => 0, 'm3.2xlarge' => 0,
      'c1.medium' => 350, 'c1.xlarge' => 1690,
      'hi1.4xlarge' => 2048,
      'cg1.4xlarge' => 1690,
      'cc1.4xlarge' => 1690, 'cc2.8xlarge' => 3370,
      't1.micro' => 160,
      'm3.xlarge' => 0, 'm3.xlarge' => 0,
      'cr1.8xlarge' => 240,
      'hs1.8xlarge' => 48000,
    }
    @@Platform_Lookup = {
      'm1.small' => 32, 'm1.medium' => 32, 'm1.large' => 64, 'm1.xlarge' => 64,
      'm2.xlarge' => 64, 'm2.2xlarge' => 64, 'm2.4xlarge' => 64, 'm2.8xlarge' => 64,
      'm3.xlarge' => 64, 'm3.2xlarge' => 64,
      'c1.medium' => 32, 'c1.xlarge' => 64,
      'hi1.4xlarge' => 64,
      'cg1.4xlarge' => 64,
      'cc1.4xlarge' => 64, 'cc2.8xlarge' => 64,
      't1.micro' => 32,
      'm3.xlarge' => 64, 'm3.xlarge' => 64,
      'cr1.8xlarge' => 64,
      'hs1.8xlarge' => 64,
    }
    @@Compute_Units_Lookup = {
      'm1.small' => 1, 'm1.medium' => 2, 'm1.large' => 4, 'm1.xlarge' => 8,
      'm2.xlarge' => 6, 'm2.2xlarge' => 13, 'm2.4xlarge' => 26, 'm2.8xlarge' => 52,
      'm3.xlarge' => 13, 'm3.2xlarge' => 26,
      'c1.medium' => 5, 'c1.xlarge' => 20,
      'hi1.4xlarge' => 35,
      'cg1.4xlarge' => 34,
      'cc1.4xlarge' => 34, 'cc2.8xlarge' => 88,
      't1.micro' => 2,
      'cr1.8xlarge' => 88,
      'hs1.8xlarge' => 35,
      'unknown' => 0,
    }
    @@Virtual_Cores_Lookup = {
      'm1.small' => 1, 'm1.medium' => 1, 'm1.large' => 2, 'm1.xlarge' => 4,
      'm2.xlarge' => 2, 'm2.2xlarge' => 4, 'm2.4xlarge' => 8, 'm2.8xlarge' => 16,
      'm3.xlarge' => 4, 'm3.2xlarge' => 8,
      'c1.medium' => 2, 'c1.xlarge' => 8,
      'hi1.4xlarge' => 16,
      'cg1.4xlarge' => 8,
      'cc1.4xlarge' => 8, 'cc2.8xlarge' => 16,
      't1.micro' => 0,
      'cr1.8xlarge' => 16,
      'hs1.8xlarge' => 16,
      'unknown' => 0,
    }
  end
end
