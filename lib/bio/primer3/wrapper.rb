require 'open3'
require 'tmpdir'
require 'bio'
require 'pp'

class Bio::Primer3
  # Can only handle single records to be passed at one time to primer3
  def self.run(primer3_options_hash)
    default_options = {}
    unless primer3_options_hash.key?('PRIMER_THERMODYNAMIC_PARAMETERS_PATH')
      @@thermodynamic_parameters_path ||= Bio::Primer3.compute_thermodynamic_parameters_path
      unless @@thermodynamic_parameters_path.nil?
        default_options['PRIMER_THERMODYNAMIC_PARAMETERS_PATH'] = @@thermodynamic_parameters_path
      end
    end
    merged_hash = default_options.merge(primer3_options_hash)
    
    input = BoulderIO::Record.new(merged_hash)

    result = Bio::Primer3::Result.new
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Open3.popen3('primer3_core') do |stdin, stdout, stderr|
          stdin.puts input.to_s
          stdin.close

          error  = stderr.readlines
          raise Exception, error unless error.nil? or error==[]

          result.output_hash = BoulderIO::Record.create(stdout.read).attributes
        end
      end
    end

    return result
  end
  
  # By default, primer3_core can't find it's own parameters path
  # (parameter PRIMER_THERMODYNAMIC_PARAMETERS_PATH) unless it is 
  # specified. This method computes the correct path based on the location
  # of the primer3 executable, and returns the parameters folder
  # based on it, or nil if none can be found
  def self.compute_thermodynamic_parameters_path
    guessed_path = File.join(
      File.dirname(`which primer3_core`),
      'primer3_config/'
      )
    return nil unless File.exist?(guessed_path) and File.directory?(guessed_path)
    return guessed_path
  end
  
  # Ask primer3 if 2 primers are compatible, without regard to the sequence
  # that they PCR. i.e. work out if there is any primer dimer issue, for instance
  # or whether they have disparate melting temperatures
  def self.test_primer_compatibility(primer1, primer2, other_primer3_options_hash={})
    hash = {
      'SEQUENCE_PRIMER'=>primer1,
      'SEQUENCE_PRIMER_REVCOMP'=>primer2,
      'PRIMER_TASK'=>'check_primers',
    }.merge(other_primer3_options_hash)
    
    return Bio::Primer3.run(hash).primer_found?
  end
end
