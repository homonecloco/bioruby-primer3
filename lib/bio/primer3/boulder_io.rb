# A class for input and output of Boulder I/O files, for instance as used in
# primer3. This (I don't think) is a full implementation of the Boulder I/O
# format, but serves for my purposes.
class BoulderIO
  include Enumerable

  class ParseException<Exception; end

  class Record
    include Enumerable
    attr_accessor :attributes # a hash of key-value pairs
    
    # Initialise, setting the hash optionally. If no hash is specified, then the
    # attributes will be an empty hash
    def initialize(hash=nil)
      @attributes = hash
      @attributes ||= {}
    end

    def to_s
      ats = @attributes.collect do |key,value|
        "#{key}=#{value}\n"
      end
      "#{ats.join("")}="
    end

    # Given a Boulder I/O formatted string, parse into a record
    def self.create(boulder_io_string)
      baby = self.new

      boulder_io_string.split("\n").each do |line|
        line.strip!
        break if line=='=' #break on the final record

        splits = line.split('=')

        # error checking
        if splits.length != 2
          raise ParseException, "Could not parse Boulder I/O line: `#{line}', quitting"
        end

        baby[splits[0]] = splits[1]
      end
      baby #return the new'un for convenience
    end

    # for Enumerable-compatibility
    def each
      @attributes.each do |k,v|
        yield k,v
      end
    end

    # Equivalent to attributes[] - this is a convenient method, isn't it?
    def [](key)
      @attributes[key]
    end

    # Equivalent to attributes[]= - this is a convenient method, isn't it?
    def []=(key,value)
      @attributes[key] = value
    end
  end

  # an array of records
  attr_accessor :records

  # Open a Boulder I/O file and parse it. It is possible to go through all the
  # records:
  #
  #    BoulderIO.open('/path/to/boulderio_file').each {|record| record}
  def self.open(filename)
    record_strings = File.open(filename).read.split("\n=\n")
    @records = record_strings.collect do |s|
      Record.create(s)
    end
    @records # return the records for convenience
  end

  # for Enumerable-compatibility
  def each
    @records.each do |r|
      yield r
    end
  end
end
