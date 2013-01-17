require 'set'

require './dbsnp'
require './snp'

class SNP
	attr_accessor :dbsnp_xml

	def self.load_dbSNP(rsid)
		# puts "loading #{rsid}"
		xml = DbSNP[rsid]

		snp = SNP.new(rsid)
		snp.chr = xml.css("Rs Component")[0]["chromosome"]

		if xml.css("ClinicalSignificance").count > 0 then
			snp.clinical_significance = xml.css("ClinicalSignificance")[0].text
		end

		genes = Set.new

		xml.css("FxnSet").each do |fxnset|
			genes << fxnset[:symbol] if fxnset[:symbol]
		end

		snp.genes = genes.to_a

		snp
	end
end