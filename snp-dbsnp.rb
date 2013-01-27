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

	private
	def create_allele?(seq)
		allele = self.alleles[seq]

		if !allele then
			allele = Allele.new(seq)
			self.alleles[seq] = allele
		end

		allele
	end

	private
	def self.load_maploc(snp, xml)
		xml.css("FxnSet").each do |fxnset|
			load_fxnset(snp, fxnset)
		end
	end

	private
	def self.load_fxnset(snp, xml)
		
	end
end