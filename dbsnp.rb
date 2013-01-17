require 'bio'
require 'nokogiri'
require 'stringio'
require 'zip/zipfilesystem'

require './config'

Bio::NCBI.default_email = CONFIG[:ncbi_email]

class CacheDir
	def initialize(dir)
		@dir = dir
	end

	private
	def make_cache_filename(rsid)
		"#{@dir}/#{rsid}.xml"
	end

	public
	def open(rsid, &block)
		File.open(make_cache_filename(rsid), "r", &block)
	end

	def write(rsid, xml)
		File.open(make_cache_filename(rsid), "w") do |io|
			io << xml
		end
	end

	def exists?(rsid)
		File.exists?(make_cache_filename(rsid))
	end

	def delete(rsid)
		File.delete(make_cache_filename(rsid))
	end

	def flush
	end
end

require 'sqlite3'

class CacheSqlite
	def initialize(pathname)
		@db = SQLite3::Database.new(pathname)
		@db.execute <<-SQL
			create table if not exists dbsnp (
				rsid varchar(32) constraint rsid_unique unique on conflict fail,
				xml text
			);
			create unique index if not exists dbsnp_rsid on dbsnp (
				rsid asc
			);
		SQL
	end

	def open(rsid, &block)
		record = @db.execute("SELECT xml FROM dbsnp WHERE rsid = ?",
							 rsid)[0]
		
		if record then
			io = StringIO.new(record[0])
		end

		if block != nil then
			block.(io)
		else
			return io
		end
	end

	def write(rsid, xml)
		puts "insert"
		puts @db.execute("INSERT OR REPLACE INTO dbsnp (rsid, xml) VALUES (?, ?)",
						 rsid, xml)
	end

	def exists?(rsid)
		@db.execute("SELECT COUNT(rsid) FROM dbsnp WHERE rsid = ?", rsid) do |result|
			return result[0][0] > 0
		end
	end

	def delete(rsid)
		@db.execute("DELETE FROM dbsnp WHERE rsid = ?", rsid)
	end

	def flush
	end
end

module DbSNP
	if CONFIG[:dbsnp_cache_sqlite] then
		CACHE = CacheSqlite.new(CONFIG[:dbsnp_cache_sqlite])
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
		# remove leading "rs", if any
		if rsid =~ /^rs([0-9]+)/ then
			rsid = $1
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