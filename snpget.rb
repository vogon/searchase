require 'bio'
require 'nokogiri'
require 'stringio'

Bio::NCBI.default_email = "vogon@icculus.org"

cache_dir = "."

def make_cache_filename(rsid)
	"#{cache_dir}/dbsnp_cache/#{rsid}.xml"
end

def store_snp_to_cache(rsid, xml)
	open(make_cache_filename(rsid), "w") do |io|
		io << xml.to_xml(:indent => 4)
	end
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

	begin
		result = ncbi.efetch(rsid, {"db"=>"snp", "retmode"=>"xml"})
	rescue EOFError
		retry
	rescue Errno::ECONNRESET
		retry
	rescue Errno::ETIMEDOUT
		retry
	end

	StringIO.new(result)
end

def get_snp(rsid)
	# remove leading "rs", if any
	if rsid =~ /^rs([0-9]+)/ then
		rsid = $1
	end

	snp_io = fetch_snp_from_cache(rsid)

	if snp_io.nil? then
		snp_io = fetch_snp_from_entrez(rsid)
	end

	snp_xml = Nokogiri::XML(snp_io) do |config|
		config.default_xml.noblanks
	end

	store_snp_to_cache(rsid, snp_xml)

	snp_xml
end

if __FILE__ == $0 then
	rsid = ARGV[0]

	get_snp(rsid)
end