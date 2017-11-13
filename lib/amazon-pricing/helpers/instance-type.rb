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
                'T2' => ['t2.nano', 't2.micro', 't2.small', 't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge']
            }
        },
        'ComputeOptimized' => {
            'CurrentGen' => {
                'C3' => ['c3.large', 'c3.xlarge', 'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge'],
                'C4' => ['c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge'],
                'C5' => ['c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge', 'c5.9xlarge', 'c5.18xlarge'],
            },
            'PreviousGen' => {
                'C1' => ['c1.medium', 'c1.xlarge', 'cc1.4xlarge'],
                'C2' => ['cc2.8xlarge']
            }
        },
        'MemoryOptimized' => {
            'CurrentGen' => {
                'R3'  => ['r3.large', 'r3.xlarge', 'r3.2xlarge', 'r3.4xlarge', 'r3.8xlarge'],
                'R4'  => ['r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge', 'r4.8xlarge', 'r4.16xlarge'],
                'X1'  => ['x1.16xlarge', 'x1.32xlarge'],
                'X1E'  => ['x1e.32xlarge'],
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
                'I3'  => ['i3.large', 'i3.xlarge', 'i3.2xlarge', 'i3.4xlarge', 'i3.8xlarge', 'i3.16xlarge'],
                'D2'  => ['d2.xlarge', 'd2.2xlarge', 'd2.4xlarge', 'd2.8xlarge']
            },
            'PreviousGen' => {
                'HI1' => ['hi1.4xlarge']
            }
        },
        'GPUInstances' => { # NB: noted as of 2017-10, AWS now categorizes as "AcceleratedComputing"
            'CurrentGen' => { # G2=GPU Graphics, G3=GPU-3 Graphics, P2=GPU Computes, P3=GPU-3 Computes, F1=FPGA Accelerated
                'G2'  => ['g2.2xlarge', 'g2.8xlarge'],
                'G3'  => ['g3.4xlarge', 'g3.8xlarge', 'g3.16xlarge'],
                'P2'  => ['p2.xlarge', 'p2.8xlarge', 'p2.16xlarge'],
                'P3'  => ['p3.2xlarge', 'p3.8xlarge', 'p3.16xlarge'],
                'F1'  => ['f1.2xlarge', 'f1.16xlarge'],
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

      # note: the next smaller type may _not_ be supported for a given family
      #  so this returns the next logical/possible smaller type, but not necessarily
      #  the next valid type
      def next_smaller_type(name)
        fam,type = name.split('.')
        orig_nf = size_to_nf[type]
        return nil unless orig_nf
        # paranoia: assumes size_to_nf may not be sorted, which we need to step down
        sorted_size_to_nf = {}
        size_to_nf.sort_by(&:last).each do |(size,nf)|
          sorted_size_to_nf[size] = nf
        end
        size_keys = sorted_size_to_nf.keys
        idx = size_keys.index(type)
        idx = idx -1  if (idx > 0)  # don't go smaller, than smallest
        nf = sorted_size_to_nf[new_type = size_keys.at(idx)]

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
          "9xlarge" => 72,
          "10xlarge" => 80,
          "16xlarge" => 128,
          "18xlarge" => 144,
          "32xlarge" => 256,
      }
      NF_TO_SIZE_TABLE = SIZE_TO_NF_TABLE.invert

    end
  end
end
