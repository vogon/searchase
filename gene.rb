require './gene-entrezgene'

class Gene
	@@genes = {}

	def initialize(id)
		self.id = id
		@@genes[id] = self

		yield self if block_given?
	end

	def self.[](id)
		if @@genes[id] then
			@@genes[id]
		else
			Gene.load_entrezgene(id)
		end
	end

	attr_accessor :id
	attr_accessor :symbol
	attr_accessor :coding_strand
end