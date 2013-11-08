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
		'mysql_multiAZ'=> 'MySQL Community Edition (Multi-AZ)',
		'oracle_se1_standard'=> 'Oracle Database Standard Edition One',
		'oracle_se1_multiAZ'=> 'Oracle Database Standard Edition One (Multi-AZ)',
		'oracle_se1_byol'=> 'Oracle Database Standard Edition One (BYOL)',
		'oracle_se1_byol_multiAZ'=> 'Oracle Database Standard Edition One (BYOL, Multi-AZ)',
		'oracle_se_byol'=> 'Oracle Database Standard Edition (BYOL)',
		'oracle_se_byol_multiAZ'=> 'Oracle Database Standard Edition (BYOL, Multi-AZ)',
		'oracle_ee_byol'=> 'Oracle Database Enterprise Edition (BYOL)',
		'oracle_ee_byol_multiAZ'=> 'Oracle Database Enterprise Edition (BYOL, Multi-AZ)',
		'sqlserver_ex'=> 'Microsoft SQL Server Express Edition',
		'sqlserver_web'=> 'Microsoft SQL Server Web Edition',
		'sqlserver_se_standard'=> 'Microsoft SQL Server Standard Edition',
		'sqlserver_se_byol'=> 'Microsoft SQL Server Standard Edition (BYOL)',
		'sqlserver_ee_byol'=> 'Microsoft SQL Server Enterprise Edition (BYOL)'	
	  }

  	def display_name(name)
	  @@Database_Name_Lookup[name]
  	end
  end
end