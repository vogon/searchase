# abstract SNP object model

require './snp-dbsnp'

class SNP
	@@snps = {}

	def initialize(rsid)
		self.rsid = rsid
		@@snps[rsid] = self

		self.alleles = {}

		yield self if block_given?
	end

	def self.[](rsid)
		if @@snps[rsid] then
			@@snps[rsid]
		else
			SNP.load_dbSNP(rsid)
		end
	end

	attr_accessor :rsid
	attr_accessor :chr

	attr_accessor :clinical_significance

	attr_accessor :genes
	attr_accessor :alleles
end

class Allele
	def initialize(sequence)
		self.sequence = sequence
		self.mappings = []
		yield self if block_given?
	end

	attr_accessor :sequence
	attr_accessor :mappings
end

class Mapping
	def initialize
		yield self if block_given?
	end

	attr_accessor :gene

	attr_accessor :function_class
	attr_accessor :so_term
end