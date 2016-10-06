module AwsPricing
  module Helper
    module InstanceType

      @@INSTANCE_TYPES_BY_CLASSIFICATION = {
        'GeneralPurpose' => {
            'CurrentGen' => {
                'M3' => ['m3.medium', 'm3.large', 'm3.xlarge', 'm3.2xlarge'],
                'M4' => ['m4.large', 'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 'm4.16xlarge']
            },
            'PreviousGen' => {
                'M1' => ['m1.small', 'm1.medium', 'm1.large', 'm1.xlarge']
            }
        },
        'BurstableInstances' => {
            'CurrentGen' => {
                'T2' => ['t2.nano', 't2.micro', 't2.small', 't2.medium', 't2.large']
            }
        },
        'ComputeOptimized' => {
            'CurrentGen' => {
                'C3' => ['c3.large', 'c3.xlarge', 'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge'],
                'C4' => ['c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge']
            },
            'PreviousGen' => {
                'C1' => ['c1.medium', 'c1.xlarge', 'cc1.4xlarge'],
                'C2' => ['cc2.8xlarge']
            }
        },
        'MemoryOptimized' => {
            'CurrentGen' => {
                'R3'  => ['r3.large', 'r3.xlarge', 'r3.2xlarge', 'r3.4xlarge', 'r3.8xlarge'],
                'X1'  => ['x1.32xlarge']
            },
            'PreviousGen' => {
                'M2'  => ['m2.xlarge', 'm2.2xlarge', 'm2.4xlarge'],
                'CR1' => ['cr1.8xlarge']
            }
        },
        'StorageOptimized' => {
            'CurrentGen' => {
                'HS1' => ['hs1.8xlarge'],
                'I2'  => ['i2.xlarge', 'i2.2xlarge', 'i2.4xlarge', 'i2.8xlarge'],
                'D2'  => ['d2.xlarge', 'd2.2xlarge', 'd2.4xlarge', 'd2.8xlarge']
            },
            'PreviousGen' => {
                'HI1' => ['hi1.4xlarge']
            }
        },
        'GPUInstances' => {
            'CurrentGen' => { # G2=GPU Graphics, P2=GPU Computes
                'G2'  => ['g2.2xlarge', 'g2.8xlarge'],
                'P2'  => ['p2.xlarge', 'p2.8xlarge', 'p2.16xlarge'],
            },
            'PreviousGen' => {
                'CG1' => ['cg1.4xlarge']
            }
        },
        'MicroInstances' => {
            'PreviousGen' => {
                'T1' => ['t1.micro']
            }
        }
      }

      # Important: Members of a family must be kept in 'size' order (small, medium, large, etc.)
      # AWS Docs: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html
      def instance_types
        @@INSTANCE_TYPES_BY_CLASSIFICATION
      end

      def general_purpose_instances
        instance_types['GeneralPurpose']
      end

      def burstable_instances
        instance_types['BurstableInstances']
      end

      def compute_optimized_instances
        instance_types['ComputeOptimized']
      end

      def memory_optimized_instances
        instance_types['MemoryOptimized']
      end

      def storage_optimized_instances
        instance_types['StorageOptimized']
      end

      def gpu_instances
        instance_types['GPUInstances']
      end

      def micro_instances
        instance_types['MicroInstances']
      end

      def previous_generation_instances
        [
          general_purpose_instances['PreviousGen'],
          compute_optimized_instances['PreviousGen'],
          compute_optimized_instances['PreviousGen'],
          memory_optimized_instances['PreviousGen'],
          memory_optimized_instances['PreviousGen'],
          storage_optimized_instances['PreviousGen'],
          gpu_instances['PreviousGen'],
          micro_instances['PreviousGen']
        ].inject({}) do |instances, family|
          instances.merge(family)
        end
      end

      def current_generation_instances
        [
          general_purpose_instances['CurrentGen'],
          burstable_instances['CurrentGen'],
          compute_optimized_instances['CurrentGen'],
          compute_optimized_instances['CurrentGen'],
          memory_optimized_instances['CurrentGen'],
          memory_optimized_instances['CurrentGen'],
          storage_optimized_instances['CurrentGen'],
          gpu_instances['CurrentGen']
        ].inject({}) do |instances, family|
          instances.merge(family)
        end
      end

      def all_instances
        @all_instances ||= begin
          [previous_generation_instances, current_generation_instances].inject({}) do |instances, family|
            instances.merge(family)
          end
        end
      end

      def family(api_name)
        all_instances.select { |family, instances| instances.include?(api_name) }.keys.first
      end

      def family_members(api_name)
        all_instances.select { |family, instances| instances.include?(api_name) }.values.first
      end


      def api_name_to_nf(name)
        size_to_nf[name.split('.').last]
      end

      def next_smaller_type(name)
        fam,type = name.split('.')
        nf= size_to_nf[type] / 2.0
        new_type = NF_TO_SIZE_TABLE[nf] || NF_TO_SIZE_TABLE[nf.to_i] # 2.0 and 2 are no same when used as hash keys.
        ["#{fam}.#{new_type}" , nf]
      end

      def size_to_nf
        SIZE_TO_NF_TABLE
      end

      def nf_to_size
        NF_TO_SIZE_TABLE
      end

      SIZE_TO_NF_TABLE = {
          "nano"    => 0.25,
          "micro"   => 0.5,
          "small"   => 1,
          "medium"  => 2,
          "large"   => 4,
          "xlarge"  => 8,
          "2xlarge" => 16,
          "4xlarge" => 32,
          "8xlarge" => 64,
          "10xlarge" => 80,
          "16xlarge" => 128,
          "32xlarge" => 256
      }
      NF_TO_SIZE_TABLE = SIZE_TO_NF_TABLE.invert

    end
  end
end
