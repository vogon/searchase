require 'bio'
require 'nokogiri'
require 'stringio'

require './config'
require './cache-dir'
require './cache-sqlite'

Bio::NCBI.default_email = CONFIG[:ncbi_email]

module EntrezGene
	if CONFIG[:entrezgene_cache_sqlite] then
		CACHE = CacheSqlite.new("entrezgene", CONFIG[:entrezgene_cache_sqlite])
	else
		CACHE = CacheDir.new(CONFIG[:entrezgene_cache_dir])
	end

	private
	def self.store_to_cache(id, xml)
		CACHE.write(id, xml)
	end

	private
	def self.fetch_from_cache(id)
		if CACHE.exists?(id) then
			#puts "fetching rs#{rsid} from cache..."

			CACHE.open(id)
		else
			nil
		end
	end

	private 
	def self.purge_from_cache(id)
		CACHE.delete(id)
	end

	private
	def self.fetch_from_entrez(id)
		puts "fetching gene #{id} from entrez..."

		ncbi = Bio::NCBI::REST.new

		begin
			result = ncbi.efetch(id, {"db"=>"gene", "retmode"=>"xml"})
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
		xml.css("Entrezgene").length > 0
	end

	private
	class InsaneXML < Exception
	end

	public
	def self.[](gene_id)
		begin
			gene_io = fetch_from_cache(gene_id)

			if gene_io.nil? then
				writeback = true
				gene_io = fetch_from_entrez(gene_id)
			end

			gene_xml = Nokogiri::XML(gene_io) do |config|
				config.default_xml.noblanks
			end

			if !(xml_sane?(gene_xml)) then
				puts "found insane xml for #{gene_id}, flushing and retrying"

				gene_io.close
				purge_from_cache(gene_id)

				raise InsaneXML
			end
		rescue InsaneXML
			retry
		end

		if writeback then
			store_to_cache(gene_id, gene_xml.to_xml(:spaces => 4))
		end

		gene_xml
	end

	def self.flush
		CACHE.flush
	end
end

if __FILE__ == $0 then
	rsid = ARGV[0]

	EntrezGene[rsid]

	EntrezGene.flush
end