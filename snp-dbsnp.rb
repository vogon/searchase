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

		xml.css("MapLoc").each do |maploc|
			load_maploc(snp, xml)
		end

		genes = Set.new

		xml.css("FxnSet").each do |fxnset|
			genes << fxnset[:symbol] if fxnset[:symbol]
		end

		snp.genes = genes.to_a

		snp
	end
	
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
		# get the relevant alleles (all alleles if not specified)
		if xml["allele"] then
			alleles = [snp.create_allele?(xml["allele"])]
		else
			alleles = snp.alleles.values
		end

		mapping = Mapping.new
		mapping.gene_id = xml["geneId"]
		mapping.symbol = xml["symbol"]
		mapping.function_class = xml["fxnClass"]
		mapping.so_term = xml["soTerm"]

		alleles.each do |allele|
			allele.mappings << mapping
		end
	end
end