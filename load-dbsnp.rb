require './snp'
require './dbsnp'

# loader for dbSNP data
class SNP
	def self.load_dbSNP(id)
		snp_xml = DbSNP[id]
		return nil if !snp_xml

		SNP.new(id) do |snp|
			snp.chr = snp_xml.css("Rs Component")[0]["chromosome"]

			if snp_xml.css("ClinicalSignificance").count > 0 then
				snp.clinical_significance = 
					snp_xml.css("ClinicalSignificance")[0].text
			end

			# build alleles
			observed = snp_xml.css("Rs > Sequence Observed")[0].text

			parse_nt_set(observed).each do |seq|
				snp.alleles[seq] = Allele.new(seq)
			end

			snp_xml.css("MapLoc").each do |maploc|
				load_maploc(snp, snp_xml)
			end
		end
	end

	private
	def self.load_maploc(snp, xml)
		xml.css("FxnSet").each do |fxnset|
			load_fxnset(snp, fxnset)
		end
	end

	private
	def self.load_fxnset(snp, xml)
		# build a mapping
		gene_id = xml["geneId"].to_i
		mapping = Mapping.new(gene_id) do |mapping|
			mapping.symbol = xml["symbol"]
			mapping.function_class = xml["fxnClass"]
			mapping.so_term = xml["soTerm"]
		end

		# add mapping to the relevant alleles (all alleles if not
		# specified)
		allele = xml["allele"]

		if allele then
			matching_allele = snp.alleles[allele]
			fail if !matching_allele

			alleles = [matching_allele]
		else
			alleles = snp.alleles.values
		end

		alleles.each do |allele|
			allele.mappings[gene_id] = mapping
		end
	end

	# parse a set of nucleotides into individual alleles
	private
	def self.parse_nt_set(set)
		nts = set.split('/')

		# check to make sure that they're all things I expect
		nts.each do |nt|
			fail if !"ATCG".index(nt)
		end

		nts
	end
end

puts SNP.load_dbSNP("rs5907").inspect