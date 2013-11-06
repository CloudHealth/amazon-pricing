require 'amazon-pricing/instance-type'
module AwsPricing
  class Ec2InstanceType < InstanceType
    
    # Returns whether an instance_type is available. 
    # operating_system = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def available?(type_of_instance = :ondemand, operating_system = :linux)
      os = get_category_type(operating_system)
      return false if os.nil?
      os.available?(type_of_instance)
    end

    # operating_system = :linux, :mswin, :rhel, :sles, :mswinSQL, :mswinSQLWeb
    # type_of_instance = :ondemand, :light, :medium, :heavy
    def update_pricing(operating_system, type_of_instance, json)
      os = get_category_type(operating_system)
      if os.nil?
        os = OperatingSystem.new(self, operating_system)
        @category_types[operating_system] = os
      end

      if type_of_instance == :ondemand
        # e.g. {"size"=>"sm", "valueColumns"=>[{"name"=>"linux", "prices"=>{"USD"=>"0.060"}}]}
        values = Ec2InstanceType::get_values(json, operating_system)
        price = coerce_price(values[operating_system.to_s])
        os.set_price_per_hour(type_of_instance, nil, price)
      else
        json['valueColumns'].each do |val|
          price = coerce_price(val['prices']['USD'])

          case val["name"]
          when "yrTerm1"
            os.set_prepay(type_of_instance, :year1, price)
          when "yrTerm3"
            os.set_prepay(type_of_instance, :year3, price)
          when "yrTerm1Hourly"
            os.set_price_per_hour(type_of_instance, :year1, price)
          when "yrTerm3Hourly"
            os.set_price_per_hour(type_of_instance, :year3, price)
          end
        end
      end
    end

    # Maintained for backward compatibility reasons
    def operating_systems
      category_types
    end

    protected
    # Returns [api_name, name]
    def self.get_name(instance_type, api_name, is_reserved = false)
      # Let's handle new instances more gracefully
      unless @@Memory_Lookup.has_key? api_name
        raise UnknownTypeError, "Unknown instance type #{instance_type} #{api_name}", caller
      end

      name = @@Name_Lookup[api_name]

      [api_name, name]
    end


    @@Name_Lookup = {
      'm1.small' => 'Standard Small', 'm1.medium' => 'Standard Medium', 'm1.large' => 'Standard Large', 'm1.xlarge' => 'Standard Extra Large',
      'm2.xlarge' => 'Hi-Memory Extra Large', 'm2.2xlarge' => 'Hi-Memory Double Extra Large', 'm2.4xlarge' => 'Hi-Memory Quadruple Extra Large',
      'm3.xlarge' => 'M3 Extra Large Instance', 'm3.2xlarge' => 'M3 Double Extra Large Instance',
      'c1.medium' => 'High-CPU Medium', 'c1.xlarge' => 'High-CPU Extra Large',
      'hi1.4xlarge' => 'High I/O Quadruple Extra Large',
      'cg1.4xlarge' => 'Cluster GPU Quadruple Extra Large',
      'cc1.4xlarge' => 'Cluster Compute Quadruple Extra Large', 'cc2.8xlarge' => 'Cluster Compute Eight Extra Large',
      't1.micro' => 'Micro',
      'cr1.8xlarge' => 'High-Memory Cluster Eight Extra Large',
      'hs1.8xlarge' => 'High-Storage Eight Extra Large',
      'g2.2xlarge' => 'Cluster GPU Double Extra Large',
    }    
   end
end
