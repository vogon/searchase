require 'snpget'

class SNP
	def SNP.load_from_dbsnp(rsid)
		xml = get_snp(rsid)

		snp = SNP.new(rsid) do |snp|
			snp.
		end
	end
end