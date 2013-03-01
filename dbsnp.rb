require 'bio'
require 'nokogiri'
require 'stringio'

require './config'
require './cache-dir'
require './cache-sqlite'

Bio::NCBI.default_email = CONFIG[:ncbi_email]

module DbSNP
	if CONFIG[:dbsnp_cache_sqlite] then
		CACHE = CacheSqlite.new("dbsnp", CONFIG[:dbsnp_cache_sqlite])
	else
		CACHE = CacheDir.new(CONFIG[:dbsnp_cache_dir])
	end

	private
	def self.store_snp_to_cache(rsid, xml)
		CACHE.write(rsid, xml)
	end

	private
	def self.fetch_snp_from_cache(rsid)
		if CACHE.exists?(rsid) then
			#puts "fetching rs#{rsid} from cache..."

			CACHE.open(rsid)
		else
			nil
		end
	end

	private 
	def self.purge_snp_from_cache(rsid)
		CACHE.delete(rsid)
	end

	private
	def self.fetch_snp_from_entrez(rsid)
		#puts "fetching rs#{rsid} from entrez..."

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

	private
	def self.xml_sane?(xml)
		xml.css("Rs").length > 0
	end

	private
	class InsaneXML < Exception
	end

	public
	def self.[](rsid)
		if rsid.is_a? Integer then
			# assume rsid
		elsif rsid =~ /^rs([0-9]+)/ then
			# definitely rsid
			rsid = $1
		else
			# not an rsid
			return nil
		end

		begin
			snp_io = fetch_snp_from_cache(rsid)

			if snp_io.nil? then
				writeback = true
				snp_io = fetch_snp_from_entrez(rsid)
			end

			snp_xml = Nokogiri::XML(snp_io) do |config|
				config.default_xml.noblanks
			end

			if !(xml_sane?(snp_xml)) then
				puts "found insane xml for #{rsid}, flushing and retrying"

				snp_io.close
				purge_snp_from_cache(rsid)

				raise InsaneXML
			end
		rescue InsaneXML
			retry
		end

		if writeback then
			store_snp_to_cache(rsid, snp_xml.to_xml(:spaces => 4))
		end

		snp_xml
	end

	def self.flush
		CACHE.flush
	end
end

if __FILE__ == $0 then
	rsid = ARGV[0]

	DbSNP[rsid]

	DbSNP.flush
end