require 'open3'
require 'tmpdir'
require 'bio'
require 'pp'

class Bio::Primer3
  # Can only handle single records to be passed at one time to primer3
  def self.run(primer3_options_hash)
    input = BoulderIO::Record.new(primer3_options_hash)
    puts 'input==='
    p input

    result = Bio::Primer3::Result.new
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Open3.popen3('primer3_core') do |stdin, stdout, stderr|
          stdin.puts input.to_s
          stdin.close

          error  = stderr.readlines
          raise error unless error.nil? or error==[]

          result.output_hash = BoulderIO::Record.create(stdout.read).attributes
        end
      end
    end

    return result
  end
  
  # Ask primer3 if 2 primers are compatible, without regard to the sequence
  # that they PCR. i.e. work out if there is any primer dimer issue, for instance
  # or whether they have disparate melting temperatures
  def self.test_primer_compatibility(primer1, primer2, other_primer3_options_hash={})
    num_middle_ns = 40
    dummy_sequence = primer1+'N'*num_middle_ns+Bio::Sequence::NA.new(primer2).reverse_complement.to_s.upcase
    hash = {
      'SEQUENCE_TEMPLATE' => dummy_sequence,
      'PRIMER_PICK_LEFT_PRIMER'=>1,
      'PRIMER_PICK_RIGHT_PRIMER'=>1,
      'PRIMER_PRODUCT_SIZE_RANGE'=>"#{dummy_sequence.length}-#{dummy_sequence.length}",
      'SEQUENCE_INTERNAL_EXCLUDED_REGION'=> "#{primer1.length+1},#{num_middle_ns}",
      'SEQUENCE_TARGET'=> "#{primer1.length+1},#{num_middle_ns}",
    }.merge(other_primer3_options_hash)
    
    result = Bio::Primer3.run hash
    puts 'output ====='
    pp result
    return false if !result.primer_found?
    
    # A primer was found. Double check to make sure that the primer
    # we wanted was actually found
    unless result['PRIMER_LEFT_0_SEQUENCE']==primer1 and result['PRIMER_RIGHT_0_SEQUENCE']==primer2
      pp result
      raise "Programming error in primer3#test_primer_compatibility - testing was not carried out correctly. Please report a bug. Thanks."
    end
    return true
  end
end
