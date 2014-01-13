require 'tmpdir'
require 'bio'
require 'pp'
require 'bio-commandeer'

class Bio::Primer3
  include Bio::Primer3Logging
  def self.log
    Bio::Primer3.new.log
  end

  # Can only handle single records to be passed at one time to primer3
  def self.run(primer3_options_hash)
    default_options = {}
    unless primer3_options_hash.key?('PRIMER_THERMODYNAMIC_PARAMETERS_PATH')
      @@thermodynamic_parameters_path ||= Bio::Primer3.compute_thermodynamic_parameters_path
      if @@thermodynamic_parameters_path.nil?
        log.warn "No primer3_config directory found, things might go awry when running primer3."
      else
        default_options['PRIMER_THERMODYNAMIC_PARAMETERS_PATH'] = @@thermodynamic_parameters_path
      end
    end
    merged_hash = default_options.merge(primer3_options_hash)

    input = BoulderIO::Record.new(merged_hash)

    log = Bio::Log::LoggerPlus['bio-primer3']
    if log.debug?
      log.debug "Primer3 input:"
      log.debug input.to_s
    end

    result = Bio::Primer3::Result.new
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        out = Bio::Commandeer.run 'primer3_core', {:stdin => input.to_s, :log => log}
        result.output_hash = BoulderIO::Record.create(out).attributes
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
      File.dirname(Bio::Commandeer.run('which primer3_core', :log => log).strip),
      'primer3_config/'
      )
    if File.exist?(guessed_path) and File.directory?(guessed_path)
      return guessed_path
    else
      return nil
    end
  end

  # Ask primer3 if 2 primers are compatible, without regard to the sequence
  # that they PCR. i.e. work out if there is any primer dimer issue, for instance
  # or whether they have disparate melting temperatures.
  #
  # Returns true/false and the Bio::Primer3::Result object.
  # other_primer3_options_hash specifies options that are passed to primer3,
  # and options gives Ruby options:
  # * :return_result: Instead of true/false being returned, an array of [true/false, primer3_output_hash]
  # is returned instead.
  def self.test_primer_compatibility(primer1, primer2, other_primer3_options_hash={}, options={})
    hash = {
      'SEQUENCE_PRIMER'=>primer1,
      'SEQUENCE_PRIMER_REVCOMP'=>primer2,
      'PRIMER_TASK'=>'check_primers',
    }.merge(other_primer3_options_hash)

    result = Bio::Primer3.run(hash)

    if options and options[:return_result]
      return result.primer_found?, result
    else
      return result.primer_found?
    end
  end
end
