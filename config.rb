CONFIG = {
	:ncbi_email => "vogon@icculus.org",
	:dbsnp_cache_dir => "./dbsnp_cache",
	# :dbsnp_cache_sqlite => "./dbsnp_cache.db",
	:in_scope? => 
		->(snpcall) do
			snpcall.chr == "22" &&
			snpcall.id.rsid? &&
			snpcall.call.called?
		end
}