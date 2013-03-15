require './snp'
require './dbsnp'
require './gene'

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

			parse_nt_set(id, observed).each do |seq|
				snp.alleles[seq] = Allele.new(seq)
			end

			# # figure out which strand the <Sequence> sequence is on
			# exemplar_ssid = snp_xml.css("Rs Sequence")[0]["exemplarSs"]
			# exemplar_ss = snp_xml.css("Ss[ssId=\"#{exemplar_ssid}\"]")[0]

			# exemplar_seq = exemplar_ss.css("Observed")[0].text
			# exemplar_set = parse_nt_set(exemplar_seq)

			# # make sure the exemplar seq matches up -- if any exemplar
			# # seq isn't attested in the rs observed seq, bomb out
			# fail if exemplar_set.any? { |nt| !observed.index(nt) }

			# snp.strand = exemplar_ss["strand"]

			snp_xml.css('Assembly[reference="true"] Component[groupTerm]').each do |component|
				component_orient = component["orientation"]
				component_rev = (component_orient == "rev")

				component.css("MapLoc").each do |maploc|
					load_maploc(snp, maploc, component_rev)
				end
			end
		end
	end

	private
	def self.complement(nt)
		case nt
		when "A" then "T"
		when "C" then "G"
		when "G" then "C"
		when "T" then "A"
		end
	end

	private
	def self.load_maploc(snp, xml, component_rev)
		orient = xml["orient"]
		maploc_rev = (orient == "reverse")

		# puts snp.orient
		snp.orient = maploc_rev

		xml.css("FxnSet").each do |fxnset|
			load_fxnset(snp, fxnset, component_rev, maploc_rev)
		end
	end

	private
	def self.load_fxnset(snp, xml, component_rev, maploc_rev)
		# puts snp, xml, component_rev, maploc_rev

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

		# if you ask nuccore for the sequence of any read, it will return the
		# sequence on the plus strand by default; 
		# if component_rev then
		# 	allele = complement(allele)
		# end

		# if maploc_rev then
		# 	allele = complement(allele)
		# end

		# if snp.strand == "bottom" then
		# 	allele = complement(allele)
		# end

		if allele then
			matching_allele = snp.alleles[allele]

			if !matching_allele then
				# warn "bizarre allele #{allele} found for #{snp.id}"
				return
			end

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
	def self.parse_nt_set(id, set)
		nts = set.split('/')

		# check to make sure that they're all things I expect
		nts.each do |nt|
			fail "#{id}, #{set}" if !"ATCG".index(nt)
		end

		nts
	end
end

if __FILE__ == $0 then
	puts SNP.load_dbSNP("rs5907").inspect
end