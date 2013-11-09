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
  class DatabaseType < CategoryType

  	@@Database_Name_Lookup = {
	    'mysql_standard'=> 'MySQL Community Edition',
		'mysql_multiaz'=> 'MySQL Community Edition (Multi-AZ)',
		'oracle_se1_standard'=> 'Oracle Database Standard Edition One',
		'oracle_se1_multiaz'=> 'Oracle Database Standard Edition One (Multi-AZ)',
		'oracle_se1_byol'=> 'Oracle Database Standard Edition One (BYOL)',
		'oracle_se1_byol_multiaz'=> 'Oracle Database Standard Edition One (BYOL, Multi-AZ)',
		'oracle_se_byol'=> 'Oracle Database Standard Edition (BYOL)',
		'oracle_se_byol_multiaz'=> 'Oracle Database Standard Edition (BYOL, Multi-AZ)',
		'oracle_ee_byol'=> 'Oracle Database Enterprise Edition (BYOL)',
		'oracle_ee_byol_multiaz'=> 'Oracle Database Enterprise Edition (BYOL, Multi-AZ)',
		'sqlserver_ex'=> 'Microsoft SQL Server Express Edition',
		'sqlserver_web'=> 'Microsoft SQL Server Web Edition',
		'sqlserver_se_standard'=> 'Microsoft SQL Server Standard Edition',
		'sqlserver_se_byol'=> 'Microsoft SQL Server Standard Edition (BYOL)',
		'sqlserver_ee_byol'=> 'Microsoft SQL Server Enterprise Edition (BYOL)'	
	  }

	  @@DB_Deploy_Types = {
	  	:mysql=>[:standard, :multiaz],
	  	:oracle_se1=>[:standard, :multiaz, :byol, :byol_multiaz],
	  	:oracle_se=>[:byol, :byol_multiaz],
	  	:oracle_ee=>[:byol, :byol_multiaz],
	  	:sqlserver_se=>[:standard, :byol],
	  	:sqlserver_ee=>[:byol]
	  }

  	def display_name(name)
	  @@Database_Name_Lookup[name]
  	end

  	def get_database_name
  		[:mysql, :oracle_se1, :oracle_se, :oracle_ee, :sqlserver_ex, :sqlserver_web, :sqlserver_se, :sqlserver_ee]
  	end

  	def get_available_types(db)
  		@@DB_Deploy_Types[db]	
  	end
  end
end