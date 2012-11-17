require 'bio'
require 'nokogiri'
require 'stringio'

Bio::NCBI.default_email = "vogon@icculus.org"

def make_cache_filename(rsid)
	"dbsnp_cache/#{rsid}.xml"
end

def store_snp_to_cache(rsid, xml)
	io = open(make_cache_filename(rsid), "w")
	io << xml.to_xml(:indent => 4)
	io.close
end

def fetch_snp_from_cache(rsid)
	filename = make_cache_filename(rsid)

	if File::exists?(filename) then
		puts "fetching rs#{rsid} from cache..."

		open(filename)
	else
		nil
	end
end

def fetch_snp_from_entrez(rsid)
	puts "fetching rs#{rsid} from entrez..."

	ncbi = Bio::NCBI::REST.new

	result = ncbi.efetch(rsid, {"db"=>"snp", "retmode"=>"xml"})
	StringIO.new(result)
end

if __FILE__ == $0 then
	rsid = ARGV[0]

	snp_io = fetch_snp_from_cache(rsid)

	if snp_io.nil? then
		snp_io = fetch_snp_from_entrez(rsid)
	end

	snp_xml = Nokogiri::XML(snp_io) do |config|
		config.default_xml.noblanks
	end

	store_snp_to_cache(rsid, snp_xml)
end