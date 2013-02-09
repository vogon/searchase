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
