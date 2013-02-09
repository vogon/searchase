require './gene'
require './entrezgene'

class Gene
	attr_accessor :entrezgene_xml

	def self.load_entrezgene(id)
		eg_xml = EntrezGene[id]
		gene = Gene.new(id)

		gene.symbol = eg_xml.css("Entrezgene_gene Gene-ref_locus").text
		gene.coding_strand = eg_xml.css("Entrezgene_locus Gene-commentary_seqs Seq-interval_strand Na-strand")[0]['value']

		gene
	end
end