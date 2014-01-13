
require 'bio-logger'
Bio::Log::LoggerPlus.new('bio-primer3')
module Bio::Primer3Logging
  def log
    Bio::Log::LoggerPlus['bio-primer3']
  end
end

require 'bio/primer3/boulder_io.rb'
require 'bio/primer3/wrapper.rb'
require 'bio/primer3/result.rb'

