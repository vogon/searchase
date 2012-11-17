require 'bio'
require 'nokogiri'
require 'stringio'

Bio::NCBI.default_email = "vogon@icculus.org"

def store_snp_to_cache(rsid, xml)
	io = open("#{rsid}.xml", "w")
	io << xml.to_xml(:indent => 4)
	io.close
end

def get_snp(rsid)
	ncbi = Bio::NCBI::REST.new

	result = ncbi.efetch(rsid, {"db"=>"snp", "retmode"=>"xml"})
	result_io = StringIO.new(result)

	Nokogiri::XML(result_io) do |config|
		config.default_xml.noblanks
	end
end

if __FILE__ == $0 then
	rsid = ARGV[0]

	snp_xml = get_snp(rsid)
	store_snp_to_cache(rsid, snp_xml)
end