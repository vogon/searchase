# abstract SNP object model

class Allele
	def initialize
		yield self if block_given?
	end

	attr_accessor :sequence
	attr_accessor :fxn_sets
end

class FxnSet
	def initialize
		yield self if block_given?
	end

	attr_accessor :symbol
	attr_accessor :fxn_class
end

class SNP
	def initialize(rsid)
		self.rsid = rsid
		yield self if block_given?
	end

	attr_accessor :rsid
	attr_accessor :chr

	attr_accessor :genes
	attr_accessor :clinical_significance
	attr_accessor :alleles
end