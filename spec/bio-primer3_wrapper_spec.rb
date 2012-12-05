require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Primer3Wrapper" do
  it "should run the example file fine" do

# This is straight from the example code, except without the P3_FILE_FLAG=1 line
example = <<EOF
SEQUENCE_ID=example
SEQUENCE_TEMPLATE=GTAGTCAGTAGACNATGACNACTGACGATGCAGACNACACACACACACACAGCACACAGGTATTAGTGGGCCATTCGATCCCGACCCAAATCGATAGCTACGATGACG
SEQUENCE_TARGET=37,21
PRIMER_TASK=generic
PRIMER_PICK_LEFT_PRIMER=1
PRIMER_PICK_INTERNAL_OLIGO=1
PRIMER_PICK_RIGHT_PRIMER=1
PRIMER_OPT_SIZE=18
PRIMER_MIN_SIZE=15
PRIMER_MAX_SIZE=21
PRIMER_MIN_TM=56
PRIMER_MAX_NS_ACCEPTED=2
PRIMER_PRODUCT_SIZE_RANGE=75-100
P3_FILE_FLAG=1
SEQUENCE_INTERNAL_EXCLUDED_REGION=37,21
PRIMER_EXPLAIN_FLAG=1
=
EOF

    example_hash = {}
    example.split("\n").reject{|s| s== '='}.each do |line|
    splits = line.split('=')
    example_hash[splits[0]]=splits[1]
    end
    
    
    result = Bio::Primer3.run(example_hash)
    result.kind_of?(Bio::Primer3::Result).should eq(true)
    
    result['SEQUENCE_ID'].should eq('example') #Something the same between the input and output
    result['PRIMER_INTERNAL_0_PENALTY'].nil?.should eq(false) #Something only in the output
  end
  
  it 'should correctly work out the path to the primer3 config directory' do
    found_path = Bio::Primer3.compute_thermodynamic_parameters_path
    found_path.match(/primer3_config\/$/).nil?.should eq(false)
    found_path.length.should > 15 #should give an actual path
  end
  
  it "should ok reasonable primers" do
    Bio::Primer3.test_primer_compatibility('NATGACNACTGACGATGCAGA', 'TCGTAGCTATCGATTTGGGT', {'PRIMER_MIN_TM'=>56, 'PRIMER_MAX_NS_ACCEPTED'=>2}).should eq(true)
  end
  
  it "should not ok reasonable primers" do
    # Won't work because there is an N in the moddle of the right primer
    Bio::Primer3.test_primer_compatibility('ATTGACACTGACGATGCAGA', 'ATACGATTTGNGGTCGGGAT', 'PRIMER_MAX_NS_ACCEPTED'=>0).should eq(false)
  end
end
