# Methods for interacting with Primer3 output.
class Bio::Primer3::Result
  attr_accessor :output_hash
  def initialize
    @output_hash ||= {}
  end

  # Was there any primers found? Assumes you were looking for a left primer, with
  # a right primer, which won't always be the case.
  def primer_found?
    @output_hash['PRIMER_PAIR_NUM_RETURNED'].to_i>0
  end
  alias_method :yeh?, :primer_found?

  # Return the requested part of the result
  def [](key)
    @output_hash[key]
  end

  # set the requested part of the result
  def []=(key,value)
    @output_hash[key] = value
  end
end
