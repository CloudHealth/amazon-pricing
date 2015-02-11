#--
# Amazon Web Services Pricing Ruby library
#
# Ruby Gem Name::  amazon-pricing
# Author::    Joe Kinsella (mailto:joe.kinsella@gmail.com)
# Copyright:: Copyright (c) 2011-2013 CloudHealth
# License::   Distributes under the same terms as Ruby
# Home::      http://github.com/CloudHealth/amazon-pricing
#++

require 'amazon-pricing/definitions/category-type'

module AwsPricing
  class DatabaseType < CategoryType

    @@Database_Name_Lookup = {
      'mysql_standard'          => 'MySQL Community Edition',
      'mysql_multiaz'           => 'MySQL Community Edition (Multi-AZ)',
      'postgresql_standard'     => 'PostgreSql Community Edition(Beta)',
      'postgresql_multiaz'      => 'PostgreSql Community Edition(Beta) (Multi-AZ)',
      'oracle_se1_standard'     => 'Oracle Database Standard Edition One',
      'oracle_se1_multiaz'      => 'Oracle Database Standard Edition One (Multi-AZ)',
      'oracle_se1_byol'         => 'Oracle Database Standard Edition One (BYOL)',
      'oracle_se1_byol_multiaz' => 'Oracle Database Standard Edition One (BYOL Multi-AZ)',
      'oracle_se_byol'          => 'Oracle Database Standard Edition (BYOL)',
      'oracle_se_byol_multiaz'  => 'Oracle Database Standard Edition (BYOL Multi-AZ)',
      'oracle_ee_byol'          => 'Oracle Database Enterprise Edition (BYOL)',
      'oracle_ee_byol_multiaz'  => 'Oracle Database Enterprise Edition (BYOL Multi-AZ)',
      'sqlserver_ex'            => 'Microsoft SQL Server Express Edition',
      'sqlserver_web'           => 'Microsoft SQL Server Web Edition',
      'sqlserver_se_standard'   => 'Microsoft SQL Server Standard Edition',
      'sqlserver_se_multiaz'    => 'Microsoft SQL Server Standard Edition (Multi-AZ)',
      'sqlserver_se_byol'       => 'Microsoft SQL Server Standard Edition (BYOL)',
      'sqlserver_se_byol_multiaz' => 'Microsoft SQL Server Standard Edition (BYOL Multi-AZ)',
      'sqlserver_ee_byol'       => 'Microsoft SQL Server Enterprise Edition (BYOL)'
    }

    @@ProductDescription = {
      'mysql'                    => 'mysql_standard',
      'mysql_multiaz'            => 'mysql_multiaz',
      'postgres'                 => 'postgresql_standard',
      'postgres_multiaz'         => 'postgresql_multiaz',
      'postgresql'               => 'postgresql_standard',
      'postgresql_multiaz'       => 'postgresql_multiaz',
      'oracle-se1(li)'           => 'oracle_se1_standard',
      'oracle-se1(byol)'         => 'oracle_se1_byol',
      'oracle-se1(li)_multiaz'   => 'oracle_se1_multiaz',
      'oracle-se1(byol)_multiaz' => 'oracle_se1_byol_multiaz',
      'oracle-se(byol)'          => 'oracle_se_byol',
      'oracle-ee(byol)'          => 'oracle_ee_byol',
      'oracle-se(byol)_multiaz'  => 'oracle_se_byol_multiaz',
      'oracle-ee(byol)_multiaz'  => 'oracle_ee_byol_multiaz',
      'sqlserver-ee(byol)'       => 'sqlserver_ee_byol',
      'sqlserver-ex(li)'         => 'sqlserver_ex',
      'sqlserver-se(byol)'       => 'sqlserver_se_byol',
      'sqlserver-se(byol)_multiaz' => 'sqlserver_se_byol_multiaz',
      'sqlserver-se(li)'         => 'sqlserver_se_standard',
      'sqlserver-se(li)_multiaz' => 'sqlserver_se_multiaz',
      'sqlserver-web(li)'        => 'sqlserver_web',
    }

	  @@DB_Deploy_Types = {
	  	:mysql        => [:standard, :multiaz],
	  	:postgresql   => [:standard, :multiaz],
	  	:oracle_se1   => [:standard, :multiaz, :byol, :byol_multiaz],
	  	:oracle_se    => [:byol, :byol_multiaz],
	  	:oracle_ee    => [:byol, :byol_multiaz],
	  	:sqlserver_se => [:standard, :multiaz, :byol, :byol_multiaz],
	  	:sqlserver_ee => [:byol]
	  }

  	def self.display_name(name)
	    @@Database_Name_Lookup[name]
  	end

  	def self.get_database_name
  	  [:mysql, :postgresql, :oracle_se1, :oracle_se, :oracle_ee, :sqlserver_ex, :sqlserver_web, :sqlserver_se, :sqlserver_ee]
  	end

  	def self.get_available_types(db)
  	  @@DB_Deploy_Types[db]	
  	end

  	def self.db_mapping(product, is_multi_az)
      if is_multi_az
        display_name(@@ProductDescription["#{product}_multiaz"])  
      else
        display_name(@@ProductDescription["#{product}"])
	    end
    end

  	def display_name
	    self.class.display_name(name)
	  end
  end
end
