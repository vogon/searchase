# abstract SNP object model

# SNP contains information about the physical existence of a locus of variation
# (i.e., its chromosome and position)
class SNP
	def initialize(id)
		self.id = id

		self.alleles = {}
		self.assays = {}

		yield self if block_given?
	end

	def merge(other)
		fail if self.id != other.id
		fail if self.chr && other.chr && (self.chr != other.chr)
		fail if self.clinical_significance && 
				other.clinical_significance &&
				self.clinical_significance != other.clinical_significance
		fail if self.strand && other.strand &&
				(self.strand != other.strand)

		new_snp = SNP.new(self.id)

		new_snp.chr = (self.chr or other.chr)
		new_snp.clinical_significance = (self.clinical_significance or 
										other.clinical_significance)
		new_snp.alleles = self.alleles.merge(other.alleles)
		new_snp.assays = self.assays.merge(other.assays)

		new_snp
	end

	attr_accessor :id
	
	attr_accessor :chr
	attr_accessor :clinical_significance
	attr_accessor :strand

	attr_accessor :alleles
	attr_accessor :assays
end

# Allele contains information about a single variation of that locus
class Allele
	def initialize(sequence)
		self.sequence = sequence

		self.mappings = {}

		yield self if block_given?
	end

	attr_accessor :sequence

	attr_accessor :mappings
end

# Mapping contains information about the use of the locus in a hypothetical or 
# known gene or noncoding product (i.e., the gene containing the locus, whether 
# the allele owning the mapping is the reference allele or a mutation, etc)
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

# Assay contains information about a measurement taken at a locus
class Assay
	def initialize(sample_id)
		self.sample_id = sample_id

		yield self if block_given?
	end

	attr_accessor :sample_id

	attr_accessor :genotype
end