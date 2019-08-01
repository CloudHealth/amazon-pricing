module AwsPricing
  module Helper
    module InstanceType


      VPC_ONLY_INSTANCE_FAMILIES = ['a1', 'c4', 'c5', 'c5d', 'c5n', 'f1', 'g3', 'g3s', 'h1', 'i3', 'i3p', 'm4', 'm5', 'm5d', 'm5a', 'm5ad',
        'p2', 'p3', 'p3dn', 'r4', 't2', 't3', 't3a', 'x1', 'x1e', 'r5', 'r5d', 'r5a', 'r5ad', 'z1d', 'u-6tb1', 'u-9tb1', 'u-12tb1']

      METAL = 'metal'.freeze
      # the following family sizes should be kept in size order, see #api_name_to_nf below
      @@INSTANCE_TYPES_BY_CLASSIFICATION = {
        'GeneralPurpose' => {
            'CurrentGen' => {
                'A1' => ['a1.medium', 'a1.large', 'a1.xlarge', 'a1.2xlarge', 'a1.4xlarge'],
                'M4' => ['m4.large', 'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 'm4.16xlarge'],
                'M5' => ['m5.large', 'm5.xlarge', 'm5.2xlarge', 'm5.4xlarge', 'm5.8xlarge', 'm5.12xlarge', 'm5.16xlarge', 'm5.24xlarge', 'm5.metal'],
                'M5D' => ['m5d.large', 'm5d.xlarge', 'm5d.2xlarge', 'm5d.4xlarge', 'm5d.8xlarge', 'm5d.12xlarge', 'm5d.16xlarge', 'm5d.24xlarge', 'm5d.metal'],
                'M5A' => ['m5a.large', 'm5a.xlarge', 'm5a.2xlarge', 'm5a.4xlarge', 'm5a.8xlarge', 'm5a.12xlarge', 'm5a.16xlarge', 'm5a.24xlarge'],
                'M5AD' => ['m5ad.large', 'm5ad.xlarge', 'm5ad.2xlarge', 'm5ad.4xlarge', 'm5ad.12xlarge', 'm5ad.24xlarge'],

            },
            'PreviousGen' => {
                'M1' => ['m1.small', 'm1.medium', 'm1.large', 'm1.xlarge'],
                'M3' => ['m3.medium', 'm3.large', 'm3.xlarge', 'm3.2xlarge'],
            }
        },
        'BurstableInstances' => {
            'CurrentGen' => {
                'T2' => ['t2.nano', 't2.micro', 't2.small', 't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge'],
                'T3' => ['t3.nano', 't3.micro', 't3.small', 't3.medium', 't3.large', 't3.xlarge', 't3.2xlarge'],
                'T3A' => ['t3a.nano', 't3a.micro', 't3a.small', 't3a.medium', 't3a.large', 't3a.xlarge', 't3a.2xlarge']

            }
        },
        'I/O Optimized' => {
            'CurrentGen' => {
                'I3EN' => ['i3en.large', 'i3en.xlarge', 'i3en.2xlarge', 'i3en.3xlarge', 'i3en.6xlarge', 'i3en.12xlarge', 'i3en.24xlarge']
            }
        },
        'ComputeOptimized' => {
            'CurrentGen' => {
                'C3' => ['c3.large', 'c3.xlarge', 'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge'],
                'C4' => ['c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge'],
                'C5' => ['c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge', 'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge', 'c5.24xlarge', 'c5.metal'],
                'C5D' => ['c5d.large', 'c5d.xlarge', 'c5d.2xlarge', 'c5d.4xlarge', 'c5d.9xlarge', 'c5d.18xlarge'],
                'C5N' => ['c5n.large', 'c5n.xlarge', 'c5n.2xlarge', 'c5n.4xlarge', 'c5n.9xlarge', 'c5n.18xlarge'],
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
                'R5' => ['r5.large', 'r5.xlarge', 'r5.2xlarge', 'r5.4xlarge', 'r5.8xlarge', 'r5.12xlarge',' r5.16xlarge', 'r5.24xlarge', 'r5.metal'],
                'R5D' => ['r5d.large', 'r5d.xlarge', 'r5d.2xlarge', 'r5d.4xlarge', 'r5d.8xlarge', 'r5d.12xlarge', 'r5a.16xlarge', 'r5d.24xlarge', 'r5d.metal'],
                'R5A' => ['r5a.large', 'r5a.xlarge', 'r5a.2xlarge', 'r5a.4xlarge', 'r5a.8xlarge', 'r5a.12xlarge', 'r5a.16xlarge', 'r5a.24xlarge'],
                'R5AD' => ['r5ad.large', 'r5ad.xlarge', 'r5ad.2xlarge', 'r5ad.4xlarge', 'r5ad.12xlarge', 'r5ad.24xlarge'],
                'X1'  => ['x1.16xlarge', 'x1.32xlarge'],
                'X1E'  => ['x1e.xlarge', 'x1e.2xlarge', 'x1e.4xlarge', 'x1e.8xlarge', 'x1e.16xlarge', 'x1e.32xlarge'],
                'Z1D' => ['z1d.large', 'z1d.xlarge', 'z1d.2xlarge', 'z1d.3xlarge', 'z1d.6xlarge', 'z1d.12xlarge', 'z1d.metal'],
                'U-6TB1' => ['u-6tb1.metal'],
                'U-9TB1' => ['u-9tb1.metal'],
                'U-12TB1' => ['u-12tb1.metal'],
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
                'I3'  => ['i3.large', 'i3.xlarge', 'i3.2xlarge', 'i3.4xlarge', 'i3.8xlarge', 'i3.16xlarge', 'i3.metal'],
                'I3P' => ['i3p.16xlarge'],
                'D2'  => ['d2.xlarge', 'd2.2xlarge', 'd2.4xlarge', 'd2.8xlarge'],
                'H1'  => ['h1.2xlarge', 'h1.4xlarge', 'h1.8xlarge', 'h1.16xlarge'],
            },
            'PreviousGen' => {
                'HI1' => ['hi1.4xlarge']
            }
        },
        'GPUInstances' => { # NB: noted as of 2017-10, AWS now categorizes as "AcceleratedComputing"
            'CurrentGen' => { # G2=GPU Graphics, G3=GPU-3 Graphics, P2=GPU Computes, P3=GPU-3 Computes, F1=FPGA Accelerated
                'G2'  => ['g2.2xlarge', 'g2.8xlarge'],
                'G3'  => ['g3.4xlarge', 'g3.8xlarge', 'g3.16xlarge'],
                'G3S' => ['g3s.xlarge'],
                'P2'  => ['p2.xlarge', 'p2.8xlarge', 'p2.16xlarge'],
                'P3'  => ['p3.2xlarge', 'p3.8xlarge', 'p3.16xlarge'],
                'P3DN' => ['p3dn.24xlarge'],
                'F1'  => ['f1.2xlarge', 'f1.4xlarge', 'f1.16xlarge'],
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
      def self.instance_types
        @@INSTANCE_TYPES_BY_CLASSIFICATION
      end

      def self.general_purpose_instances
        instance_types['GeneralPurpose']
      end

      def self.burstable_instances
        instance_types['BurstableInstances']
      end

      def self.compute_optimized_instances
        instance_types['ComputeOptimized']
      end

      def self.memory_optimized_instances
        instance_types['MemoryOptimized']
      end

      def self.storage_optimized_instances
        instance_types['StorageOptimized']
      end

      def self.gpu_instances
        instance_types['GPUInstances']
      end

      def self.micro_instances
        instance_types['MicroInstances']
      end

      def self.previous_generation_instances
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

      def self.current_generation_instances
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

      def self.all_instances
        @all_instances ||= begin
          [previous_generation_instances, current_generation_instances].inject({}) do |instances, family|
            instances.merge(family)
          end
        end
      end

      def self.family(api_name)
        all_instances.select { |family, instances| instances.include?(api_name) }.keys.first
      end

      def self.family_members(api_name)
        all_instances.select { |family, instances| instances.include?(api_name) }.values.first
      end

      def self.api_name_to_nf(name)
        type = name.split('.').last
        if (type == METAL)
          # See if our metal instance has a hard-coded nf value
          if !metal_to_nf[name].nil?
            return metal_to_nf[name]
          end
          # try to get largest size supported for family: presumes METAL is *not* in size_to_nf hash
          # assumes family_members are sorted by size
          sizes = family_members(name)
          # Return nil if we have a bogus instance type
          if sizes.nil?
            return nil
          end
          type = sizes[-1].split('.').last        # 'metal' defaults to largest size
          if sizes[-1].split('.').last == METAL
            if sizes.size == 1 # We have an instance family with only metals but no NF associated; raise an error
              return nil
            end
            type = sizes[-2].split('.').last      # 'metal' already largest, so 2nd largest
          end
        end
        full_type = type.gsub(/xl$/, 'xlarge')
        size_to_nf[full_type]
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
        idx = idx - 1  if (idx > 0)  # don't go smaller, than smallest
        nf = sorted_size_to_nf[new_type = size_keys.at(idx)]

        ["#{fam}.#{new_type}" , nf]
      end

      def self.size_to_nf
        SIZE_TO_NF_TABLE
      end

      def self.metal_to_nf
        METAL_TO_NF_TABLE
      end

      # NB: 'metal' is not in this table (since it's family specific), see #api_name_to_nf
      SIZE_TO_NF_TABLE = {
          "nano"    => 0.25,
          "micro"   => 0.5,
          "small"   => 1,
          "medium"  => 2,
          "large"   => 4,
          "xlarge"  => 8,
          "2xlarge" => 16,
          "3xlarge" => 24,
          "4xlarge" => 32,
          "6xlarge" => 48,
          "8xlarge" => 64,
          "9xlarge" => 72,
          "10xlarge" => 80,
          "12xlarge" => 96,
          "16xlarge" => 128,
          "metal" => 128,  # We will be removing this once size_to_nf is deprecated.
          "18xlarge" => 144,
          "24xlarge" => 192,
          "32xlarge" => 256,
      }
      NF_TO_SIZE_TABLE = SIZE_TO_NF_TABLE.invert

      METAL_TO_NF_TABLE = {
        'u-6tb1.metal' => 896,
        'u-9tb1.metal' => 896,
        'u-12tb1.metal' => 896,
        'i3.metal' => 128,
        'm5.metal' => 192,
        'm5d.metal' => 192,
        'r5.metal' => 192,
        'r5d.metal' => 192,
        'z1d.metal' => 96,
        'c5.metal' => 192,
        'i3en.metal' => 192
      }

    end
  end
end
