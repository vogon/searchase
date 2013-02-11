require 'set'

require './dbsnp'
require './snp'
require './gene'

class SNP
	attr_accessor :dbsnp_xml

	def self.load_dbSNP(rsid)
		# puts "loading #{rsid}"
		snp_xml = DbSNP[rsid]
		snp = SNP.new(rsid)

		snp.chr = snp_xml.css("Rs Component")[0]["chromosome"]

		if snp_xml.css("ClinicalSignificance").count > 0 then
			snp.clinical_significance = snp_xml.css("ClinicalSignificance")[0].text
		end

		snp_xml.css("MapLoc").each do |maploc|
			load_maploc(snp, snp_xml)
		end

		snp
	end
	
	def create_mapping?(gene_id)
		gene = Gene[gene_id]
		mapping = self.mappings[gene]

		if !mapping then
			mapping = Mapping.new(gene)
			self.mappings[gene] = mapping
		end

		mapping
	end

	def self.create_allele?(mapping, seq)
		allele = mapping.alleles[seq]

		if !allele then
			allele = Allele.new(seq)
			mapping.alleles[seq] = allele
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
		# get the relevant mapping
		mapping = snp.create_mapping?(xml["geneId"])

		# get the relevant alleles (all alleles if not specified)
		if xml["allele"] then
			alleles = [create_allele?(mapping, xml["allele"])]
		else
			alleles = mapping.alleles.values
		end

		alleles.each do |allele|
			allele.function_class = xml["fxnClass"]
			allele.so_term = xml["soTerm"]
		end
	end
end