# abstract SNP object model

module DNA
	class Base
		A = Base.new
		C = Base.new
		G = Base.new
		T = Base.new

		def complement
			case base 
			when A then T
			when C then G
			when G then C
			when T then A
			end
		end

		def Base.[](str)
			case str
			when "A" then A
			when "C" then C
			when "G" then G
			when "T" then T
			end
		end

		private_class_method :new
	end
end

class Allele
	def initialize
		yield self if block_given?
	end

	attr_accessor :sequence
	attr_accessor :fxn_class
	attr_accessor :frequency
end

class SNP
	def initialize(rsid)
		yield self if block_given?
	end

	attr_accessor :rsid

	attr_accessor :dbsnp_xml
	attr_accessor :twentythree_data

	attr_accessor :clinical_significance
	attr_accessor :alleles
end