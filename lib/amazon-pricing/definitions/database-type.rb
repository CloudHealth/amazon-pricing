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

    # Display Name, as seen in DBR/CUR
    MYSQL_STANDARD            = 'MySQL Community Edition'.freeze
    MYSQL_MULTIAZ             = 'MySQL Community Edition (Multi-AZ)'.freeze
    POSTGRESQL_STANDARD       = 'PostgreSql Community Edition(Beta)'.freeze
    POSTGRESQL_MULTIAZ        = 'PostgreSql Community Edition(Beta) (Multi-AZ)'.freeze
    ORACLE_SE1_STANDARD       = 'Oracle Database Standard Edition One'.freeze
    ORACLE_SE1_MULTIAZ        = 'Oracle Database Standard Edition One (Multi-AZ)'.freeze
    ORACLE_SE1_BYOL_STANDARD  = 'Oracle Database Standard Edition One (BYOL)'.freeze
    ORACLE_SE1_BYOL_MULTIAZ   = 'Oracle Database Standard Edition One (BYOL Multi-AZ)'.freeze
    ORACLE_SE2_STANDARD       = 'Oracle Database Standard Edition Two'.freeze
    ORACLE_SE2_MULTIAZ        = 'Oracle Database Standard Edition Two (Multi-AZ)'.freeze
    ORACLE_SE2_BYOL_STANDARD  = 'Oracle Database Standard Edition Two (BYOL)'.freeze
    ORACLE_SE2_BYOL_MULTIAZ   = 'Oracle Database Standard Edition Two (BYOL Multi-AZ)'.freeze
    ORACLE_SE_BYOL_STANDARD   = 'Oracle Database Standard Edition (BYOL)'.freeze
    ORACLE_SE_BYOL_MULTIAZ    = 'Oracle Database Standard Edition (BYOL Multi-AZ)'.freeze
    ORACLE_EE_BYOL_STANDARD   = 'Oracle Database Enterprise Edition (BYOL)'.freeze
    ORACLE_EE_BYOL_MULTIAZ    = 'Oracle Database Enterprise Edition (BYOL Multi-AZ)'.freeze
    SQLSERVER_EX              = 'Microsoft SQL Server Express Edition'.freeze
    SQLSERVER_WEB             = 'Microsoft SQL Server Web Edition'.freeze
    SQLSERVER_SE_STANDARD     = 'Microsoft SQL Server Standard Edition'.freeze
    SQLSERVER_SE_MULTIAZ      = 'Microsoft SQL Server Standard Edition (Multi-AZ)'.freeze
    SQLSERVER_SE_BYOL_STANDARD= 'Microsoft SQL Server Standard Edition (BYOL)'.freeze
    SQLSERVER_SE_BYOL_MULTIAZ = 'Microsoft SQL Server Standard Edition (BYOL Multi-AZ)'.freeze
    SQLSERVER_EE_STANDARD     = 'Microsoft SQL Server Enterprise Edition'.freeze
    SQLSERVER_EE_MULTIAZ      = 'Microsoft SQL Server Enterprise Edition (Multi-AZ)'.freeze
    SQLSERVER_EE_BYOL_STANDARD= 'Microsoft SQL Server Enterprise Edition (BYOL)'.freeze
    SQLSERVER_EE_BYOL_MULTIAZ = 'Microsoft SQL Server Enterprise Edition (BYOL Multi-AZ)'
    AURORA_MYSQL              = 'Amazon Aurora'.freeze              # multiaz not distinguished, MySQL not distinguished
    AURORA_POSTGRESQL         = 'Amazon Aurora PostgreSQL'.freeze   # multiaz not distinguished
    MARIADB_STANDARD          = 'MariaDB'.freeze
    MARIADB_MULTIAZ           = 'MariaDB (Multi-AZ)'.freeze

    # maps RDS description to [ engine, license, multiaz, sizeflex ]
    @@DB_ENGINE_MAP = {
        MYSQL_STANDARD            => { engine: "mysql",         license: "none", multiaz: false, sizeflex: true },
        MYSQL_MULTIAZ             => { engine: "mysql",         license: "none", multiaz: true,  sizeflex: true },
        POSTGRESQL_STANDARD       => { engine: "postgresql",    license: "none", multiaz: false, sizeflex: true },
        POSTGRESQL_MULTIAZ        => { engine: "postgresql",    license: "none", multiaz: true,  sizeflex: true },
        ORACLE_SE1_STANDARD       => { engine: "oracle-se1",    license: "li",   multiaz: false, sizeflex: false },
        ORACLE_SE1_MULTIAZ        => { engine: "oracle-se1",    license: "li",   multiaz: true,  sizeflex: false },
        ORACLE_SE1_BYOL_STANDARD  => { engine: "oracle-se1",    license: "byol", multiaz: false, sizeflex: true },
        ORACLE_SE1_BYOL_MULTIAZ   => { engine: "oracle-se1",    license: "byol", multiaz: true,  sizeflex: true },
        ORACLE_SE2_STANDARD       => { engine: "oracle-se2",    license: "li",   multiaz: false, sizeflex: false },
        ORACLE_SE2_MULTIAZ        => { engine: "oracle-se2",    license: "li",   multiaz: true,  sizeflex: false },
        ORACLE_SE2_BYOL_STANDARD  => { engine: "oracle-se2",    license: "byol", multiaz: false, sizeflex: true },
        ORACLE_SE2_BYOL_MULTIAZ   => { engine: "oracle-se2",    license: "byol", multiaz: true,  sizeflex: true },
        ORACLE_SE_BYOL_STANDARD   => { engine: "oracle-se",     license: "byol", multiaz: false, sizeflex: true },
        ORACLE_SE_BYOL_MULTIAZ    => { engine: "oracle-se",     license: "byol", multiaz: true,  sizeflex: true },
        ORACLE_EE_BYOL_STANDARD   => { engine: "oracle-ee",     license: "byol", multiaz: false, sizeflex: true },
        ORACLE_EE_BYOL_MULTIAZ    => { engine: "oracle-ee",     license: "byol", multiaz: true,  sizeflex: true },
        SQLSERVER_EX              => { engine: "sqlserver-ex",  license: "li",   multiaz: false, sizeflex: false },
        SQLSERVER_WEB             => { engine: "sqlserver-web", license: "li",   multiaz: false, sizeflex: false },
        SQLSERVER_SE_STANDARD     => { engine: "sqlserver-se",  license: "li",   multiaz: false, sizeflex: false },
        SQLSERVER_SE_MULTIAZ      => { engine: "sqlserver-se",  license: "li",   multiaz: true,  sizeflex: false },
        SQLSERVER_SE_BYOL_STANDARD=> { engine: "sqlserver-se",  license: "byol", multiaz: false, sizeflex: false },
        SQLSERVER_SE_BYOL_MULTIAZ => { engine: "sqlserver-se",  license: "byol", multiaz: true,  sizeflex: false },
        SQLSERVER_EE_STANDARD     => { engine: "sqlserver-ee",  license: "li",   multiaz: false, sizeflex: false },
        SQLSERVER_EE_MULTIAZ      => { engine: "sqlserver-ee",  license: "li",   multiaz: true,  sizeflex: false },
        SQLSERVER_EE_BYOL_STANDARD=> { engine: "sqlserver-ee",  license: "byol", multiaz: false, sizeflex: false },
        SQLSERVER_EE_BYOL_MULTIAZ => { engine: "sqlserver-ee",  license: "byol", multiaz: true,  sizeflex: false },
        AURORA_MYSQL              => { engine: "aurora",        license: "none", multiaz: true,  sizeflex: true },
        AURORA_POSTGRESQL         => { engine: "aurora-postgresql", license: "none", multiaz: true, sizeflex: true },
        MARIADB_STANDARD          => { engine: "mariadb",       license: "none", multiaz: false, sizeflex: true },
        MARIADB_MULTIAZ           => { engine: "mariadb",       license: "none", multiaz: true,  sizeflex: true },
    }.freeze
    # maps Operation to Description
    @@DB_OPERATION_TO_DESCRIPTION = {
        'CreateDBInstance:0002'.freeze => MYSQL_STANDARD,  # MySQL
        'CreateDBInstance:0003'.freeze => ORACLE_SE1_BYOL_STANDARD,  # Oracle SE1 (BYOL)
        'CreateDBInstance:0004'.freeze => ORACLE_SE_BYOL_STANDARD,  # Oracle SE (BYOL)
        'CreateDBInstance:0005'.freeze => ORACLE_EE_BYOL_STANDARD,  # Oracle EE (BYOL)
        'CreateDBInstance:0006'.freeze => ORACLE_SE1_STANDARD, # Oracle SE1 (LI)
        'CreateDBInstance:0008'.freeze => SQLSERVER_SE_BYOL_STANDARD, # SQL Server SE (BYOL)
        'CreateDBInstance:0009'.freeze => SQLSERVER_EE_BYOL_STANDARD, # SQL Server EE (BYOL)
        'CreateDBInstance:0010'.freeze => SQLSERVER_EX, # SQL Server Exp (LI)
        'CreateDBInstance:0011'.freeze => SQLSERVER_WEB, # SQL Server Web (LI)
        'CreateDBInstance:0012'.freeze => SQLSERVER_SE_STANDARD, # SQL Server SE (LI)
        'CreateDBInstance:0014'.freeze => POSTGRESQL_STANDARD,  # PostgreSQL
        'CreateDBInstance:0015'.freeze => SQLSERVER_EE_STANDARD, # SQL Server EE (LI)
        'CreateDBInstance:0016'.freeze => AURORA_MYSQL,  # Aurora MySQL
        'CreateDBInstance:0018'.freeze => MARIADB_STANDARD,  # MariaDB
        'CreateDBInstance:0019'.freeze => ORACLE_SE2_BYOL_STANDARD,  # Oracle SE2 (BYOL)
        'CreateDBInstance:0020'.freeze => ORACLE_SE2_STANDARD, # Oracle SE2 (LI)
        'CreateDBInstance:0021'.freeze => AURORA_POSTGRESQL,  # Aurora PostgreSQL
    }.freeze

    @@Database_Name_Lookup = {
      'mysql_standard'.freeze          => MYSQL_STANDARD,
      'mysql_multiaz'.freeze           => MYSQL_MULTIAZ,
      'postgresql_standard'.freeze     => POSTGRESQL_STANDARD,
      'postgresql_multiaz'.freeze      => POSTGRESQL_MULTIAZ,
      'oracle_se1_standard'.freeze     => ORACLE_SE1_STANDARD,
      'oracle_se1_multiaz'.freeze      => ORACLE_SE1_MULTIAZ,
      'oracle_se1_byol'.freeze         => ORACLE_SE1_BYOL_STANDARD,
      'oracle_se1_byol_multiaz'.freeze => ORACLE_SE1_BYOL_MULTIAZ,
      'oracle_se_byol'.freeze          => ORACLE_SE_BYOL_STANDARD,
      'oracle_se_byol_multiaz'.freeze  => ORACLE_SE_BYOL_MULTIAZ,
      'oracle_ee_byol'.freeze          => ORACLE_EE_BYOL_STANDARD,
      'oracle_ee_byol_multiaz'.freeze  => ORACLE_EE_BYOL_MULTIAZ,
      'sqlserver_ex'.freeze            => SQLSERVER_EX,
      'sqlserver_web'.freeze           => SQLSERVER_WEB,
      'sqlserver_se_standard'.freeze   => SQLSERVER_SE_STANDARD,
      'sqlserver_se_multiaz'.freeze    => SQLSERVER_SE_MULTIAZ,
      'sqlserver_se_byol'.freeze       => SQLSERVER_SE_BYOL_STANDARD,
      'sqlserver_se_byol_multiaz'.freeze => SQLSERVER_SE_BYOL_MULTIAZ,
      'sqlserver_ee_standard'.freeze     => SQLSERVER_EE_STANDARD,
      'sqlserver_ee_multiaz'.freeze      => SQLSERVER_EE_MULTIAZ,
      'sqlserver_ee_byol'.freeze         => SQLSERVER_EE_BYOL_STANDARD,
      'sqlserver_ee_byol_multiaz'.freeze => SQLSERVER_EE_BYOL_MULTIAZ,
      'aurora_standard'.freeze           => AURORA_MYSQL,
      'aurora_postgresql_standard'.freeze=> AURORA_POSTGRESQL,
      'mariadb_standard'.freeze        => MARIADB_STANDARD,
      'mariadb_multiaz'.freeze         => MARIADB_MULTIAZ,

      'oracle_se2_standard'.freeze     => ORACLE_SE2_STANDARD,
      'oracle_se2_multiaz'.freeze      => ORACLE_SE2_MULTIAZ,
      # Oracle SE2 BYOL prices are copied from Enterprise BYOL prices and not collected
      # (so no need to add rds-price-list.rb)
      'oracle_se2_byol'.freeze         => ORACLE_SE2_BYOL_STANDARD,
      'oracle_se2_byol_multiaz'.freeze => ORACLE_SE2_BYOL_MULTIAZ,
    }

    @@Display_Name_To_Qualified_Database_Name = @@Database_Name_Lookup.invert

    @@ProductDescription = {
      'mysql'.freeze                    => 'mysql_standard'.freeze,
      'mysql_multiaz'.freeze            => 'mysql_multiaz'.freeze,
      'postgres'.freeze                 => 'postgresql_standard'.freeze,
      'postgres_multiaz'.freeze         => 'postgresql_multiaz'.freeze,
      'postgresql'.freeze               => 'postgresql_standard'.freeze,
      'postgresql_multiaz'.freeze       => 'postgresql_multiaz'.freeze,
      'oracle-se(byol)'.freeze          => 'oracle_se_byol'.freeze,
      'oracle-se(byol)_multiaz'.freeze  => 'oracle_se_byol_multiaz'.freeze,
      'oracle-ee(byol)'.freeze          => 'oracle_ee_byol'.freeze,
      'oracle-ee(byol)_multiaz'.freeze  => 'oracle_ee_byol_multiaz'.freeze,
      'oracle-se1(li)'.freeze           => 'oracle_se1_standard'.freeze,
      'oracle-se1(li)_multiaz'.freeze   => 'oracle_se1_multiaz'.freeze,
      'oracle-se1(byol)'.freeze         => 'oracle_se1_byol'.freeze,
      'oracle-se1(byol)_multiaz'.freeze => 'oracle_se1_byol_multiaz'.freeze,
      'oracle-se2(li)'.freeze           => 'oracle_se2_standard'.freeze,
      'oracle-se2(li)_multiaz'.freeze   => 'oracle_se2_multiaz'.freeze,
      'oracle-se2(byol)'.freeze         => 'oracle_se2_byol'.freeze,
      'oracle-se2(byol)_multiaz'.freeze => 'oracle_se2_byol_multiaz'.freeze,
      'sqlserver-ee(byol)'.freeze       => 'sqlserver_ee_byol'.freeze,
      'sqlserver-ee(byol)_multiaz'.freeze => 'sqlserver_ee_byol_multiaz'.freeze,
      'sqlserver-ee(li)'.freeze         => 'sqlserver_ee_standard'.freeze,
      'sqlserver-ee(li)_multiaz'.freeze => 'sqlserver_ee_multiaz'.freeze,
      'sqlserver-ex(li)'.freeze         => 'sqlserver_ex'.freeze,
      'sqlserver-se(byol)'.freeze       => 'sqlserver_se_byol'.freeze,
      'sqlserver-se(byol)_multiaz'.freeze => 'sqlserver_se_byol_multiaz'.freeze,
      'sqlserver-se(li)'.freeze         => 'sqlserver_se_standard'.freeze,
      'sqlserver-se(li)_multiaz'.freeze => 'sqlserver_se_multiaz'.freeze,
      'sqlserver-web(li)'.freeze        => 'sqlserver_web'.freeze,
      'aurora'.freeze                   => 'aurora_standard'.freeze,
      'aurora-postgresql'.freeze        => 'aurora_postgresql_standard'.freeze,
      'mariadb'.freeze                  => 'mariadb_standard'.freeze,
      'mariadb_multiaz'.freeze          => 'mariadb_multiaz'.freeze,
    }

    @@DB_Deploy_Types = {
      :mysql        => [:standard, :multiaz],
      :postgresql   => [:standard, :multiaz],
      :oracle_se1   => [:standard, :multiaz, :byol, :byol_multiaz],
      :oracle_se2   => [:standard, :multiaz, :byol, :byol_multiaz],
      :oracle_se    => [:byol, :byol_multiaz],
      :oracle_ee    => [:byol, :byol_multiaz],
      :sqlserver_se => [:standard, :multiaz, :byol, :byol_multiaz],
      :sqlserver_ee => [:byol, :byol_multiaz, :standard, :multiaz],
      :aurora       => [:standard, :multiaz], # checking to see distinguished standard/multiaz
      :aurora_postgresql => [:standard, :multiaz],
      :mariadb      => [:standard, :multiaz],
    }

  	def self.display_name(name)
	    @@Database_Name_Lookup[name]
  	end

  	def self.get_database_name
      [:mysql, :postgresql, :oracle_se1, :oracle_se, :oracle_ee, :sqlserver_ex, :sqlserver_web,
        :sqlserver_se, :sqlserver_ee, :aurora, :aurora_postgresql, :mariadb,
        :oracle_se2 # oracle_se2 license included prices are collected, and BYOL prices are copied from oracle_se
      ]
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

    def self.display_name_to_qualified_database_name(display_name)
      database_name = @@Display_Name_To_Qualified_Database_Name[display_name]
      if database_name.nil?
        raise "Unknown display_name '#{display_name}'.  Valid names are #{@@Display_Name_To_Qualified_Database_Name.keys.join(', ')}"
      end
      database_name
    end

    def self.display_name_to_database_name(display_name)
      database_name = self.display_name_to_qualified_database_name(display_name)
      database_name.gsub('_standard', '').gsub('_multiaz', '').gsub('_byol', '')
    end

    def self.display_name_is_multi_az?(display_name)
      database_name = self.display_name_to_qualified_database_name(display_name)
      database_name.include? 'multiaz'
    end

    def self.display_name_is_byol?(display_name)
      database_name = self.display_name_to_qualified_database_name(display_name)
      database_name.include? 'byol'
    end

    # example: database_sf?('MySQL Community Edition (Multi-AZ)') returns true
    # Returns BOOL if database string is RDS SF
    # params:
    # - display_name[String]: fully qualified database string
    def self.database_sf?(display_name)
      db = @@DB_ENGINE_MAP[display_name]
      return false unless db            # unknown db is presumed non sf
      db[:sizeflex]
    end
    # example: operation_sf?('CreateDBInstance:0016',true) returns true
    # Returns BOOL if operation string is RDS SF
    # params:
    # - operation_name[String]: fully qualified operation string
    # - multiaz[bool]: if operation is multi-az (api for consistency purposes)
    def self.operation_sf?(operation_name,multiaz=false)
      display_name = @@DB_OPERATION_TO_DESCRIPTION[operation_name]
      return false unless display_name  # unknown operation is presumed non sf
      self.database_sf?(display_name)
    end
    # example: databases_sf() returns [MYSQL_STANDARD, ... ]
    # Returns BOOL if operation string is RDS SF
    # params: none
    def self.databases_sf
      dbs = []
      @@DB_ENGINE_MAP.each do |key,value|
        dbs << key if value[:sizeflex]
      end
      dbs
    end

    # example: database_multiaz?('MySQL Community Edition (Multi-AZ)') returns true
    # Returns BOOL if database string is RDS SF
    # params:
    # - operation_name[String]: fully qualified operation string
    def self.database_multiaz?(display_name)
      db = @@DB_ENGINE_MAP[display_name]
      return false unless db            # unknown db is presumed non sf
      db[:multiaz]
    end
    # self.operation_multiaz? not possible since az not encoded in `operation`

    # example: database_nf('MySQL Community Edition (Multi-AZ)') returns 2
    # Returns INT (nf factor) for given database string
    # params:
    # - operation_name[String]: fully qualified operation string
    def self.database_nf(display_name)
      db = @@DB_ENGINE_MAP[display_name]
      return 1 unless db                # unknown db is presumed non sf
      return 2 if db[:sizeflex] && db[:multiaz]

      1
    end
    # example: database_nf('MySQL Community Edition (Multi-AZ)',true) returns 2
    # i.e. inst_nf = RDS_NF[inst_size] * operation_nf(operation_name,multiaz)
    # Returns INT (nf factor) for given operation string and multiaz
    # params:
    # - operation_name[String]: fully qualified operation string
    # - multiaz[bool]: if operation is multi-az
    def self.operation_nf(operation_name, multiaz)
      display_name = @@DB_OPERATION_TO_DESCRIPTION[operation_name]
      return 1 unless display_name  # unknown operation is presumed non sf
      return 2 if self.operation_sf?(operation_name,multiaz) && multiaz

      1
    end

    def display_name
	    self.class.display_name(name)
	  end
  end
end
