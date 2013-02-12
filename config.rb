CONFIG = {
	:ncbi_email => "vogon@icculus.org",
	:dbsnp_cache_dir => "./dbsnp_cache",
	:entrezgene_cache_dir => "./entrezgene_cache",
	# :dbsnp_cache_sqlite => "./dbsnp_cache.db",
	:rsid_list =>
		[ 
			"rs61752732",
			"rs28940308",
			"rs62641228",
			"rs450046",
			"rs3970559",
			"rs2904552",
			"rs28939675",
			"rs5907",
			"rs34035085",
			"rs17879961",
			"rs71799110",
			"rs1135840",
			"rs16947",
			"rs1065852",
			"rs28940571",
			"rs28940572",
			"rs11090865",
			"rs28942090",
			"rs28937598",
			"rs28937868",
			"rs6151429",
			"rs28940893",
			"rs2071421",
			"rs28940894"
		],
	:in_scope? => 
		->(snpcall) do
			snpcall.chr == "22" &&
			# snpcall.id.rsid? &&
			CONFIG[:rsid_list].any? { |rsid| rsid == snpcall.id } &&
			snpcall.call.called?
		end
}