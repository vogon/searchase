# abstract SNP object model

require './snp-dbsnp'

# SNP contains information about the physical existence of a locus of variation
# (i.e., its chromosome and position)

# Allele contains information about a single variation of that locus

# Mapping contains information about the use of the locus in a hypothetical or known
# gene or noncoding product (i.e., the gene containing the locus, whether the allele owning 
# the mapping is the reference allele or a mutation, etc)

# Assay contains information about a measurement taken at a locus

# SNP
# => has-a snp id (rsid or illumina)
# => has-a chromosome
# => has-a clinical significance
#
# => has-many alleles
# => has-many assays

SNPs = {}

class SNP
	def initialize(id)
		self.id = id

		self.alleles = {}
		self.assays = {}

		yield self if block_given?
	end

	attr_accessor :id
	
	attr_accessor :chr
	attr_accessor :clinical_significance

	attr_accessor :alleles
	attr_accessor :assays
end

# Allele
# => has-a sequence
#
# => has-many mappings

class Allele
	def initialize(sequence)
		self.sequence = sequence

		self.mappings = {}

		yield self if block_given?
	end

	attr_accessor :sequence

	attr_accessor :mappings
end

# Mapping
# => has-a symbol
# => has-a entrezgene id
# => has-a function class
# => has-a so-term

class Mapping
	def initialize(id)
		self.entrezgene_id = id

		yield self if block_given?
	end

	attr_accessor :entrezgene_id
	attr_accessor :symbol

	attr_accessor :function_class
	attr_accessor :so_term
end

# Assay
# => has-a sample id
# => has-a genotype

class Assay
	def initialize(sample_id)
		self.sample_id = sample_id

		yield self if block_given?
	end

	attr_accessor :sample_id

	attr_accessor :genotype
end