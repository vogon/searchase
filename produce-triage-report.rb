require 'tilt'
require 'slim'

require './snp'
require './load-23andme'
require './load-dbsnp'

class Group
	def initialize(name = nil, predicate = nil)
		self.name = name
		self.predicate = predicate
		self.snps = []

		if block_given? then
			yield self
		end

		fail if (self.name.nil? || self.predicate.nil?)
	end

	attr_accessor :name, :predicate, :snps
end

class GroupChain
	def initialize
		@chain = []

		yield self
	end

	def each(&block)
		@chain.each &block
	end

	def group(&new_block)
		@chain << Group.new(&new_block)
	end

	def categorize(snp)
		@chain.each do |group|
			return group if group.predicate.call(snp)
		end
	end
end

GROUPS = GroupChain.new do |c|
	c.group do |g|
		g.name = 'known pathogenic SNPs'
		g.predicate = Proc.new do |snp|
			snp.clinical_significance == 'pathogenic'
		end
	end
	c.group do |g|
		g.name = 'SNPs associated with genes'
		g.predicate = Proc.new do |snp|
			snp.alleles.values.any? { |allele| allele.mappings != {} }
		end
	end
	c.group do |g| 
		g.name = 'everything else (clinical information unknown)'
		g.predicate = Proc.new do |snp|
			true
		end
	end
end

class String
	def complement
		fail if !(self =~ /^[ATCG]+$/)

		self.tr('ATCG', 'TAGC')
	end

	def rsid?
		self =~ /^rs/
	end

	def called?
		!(self =~ /-/)
	end
end

require './config'

ARGV.length >= 1 or fail "specify a SNP dump file"

summary = {}

n_snps = ARGV[1].to_i if ARGV[1]

snps = SNP.load_23andme_dump(ARGV[0])
summary[:total_count] = snps.count

scope_snps = snps.select { |id, snp| CONFIG[:in_scope?].(snp) }
summary[:scope_count] = scope_snps.count

merged_scope_snps = {}

i = 0

scope_snps.keys.each do |id|
	print "#{i}..." if i % 100 == 0

	# puts id
	dbsnp = SNP.load_dbSNP(id)
	merged_scope_snps[id] = scope_snps[id].merge(dbsnp)

	# puts scope_snps[id].inspect, dbsnp.inspect, merged_scope_snps[id].inspect

	i = i + 1

	break if n_snps && i >= n_snps
end

puts

DbSNP.flush

def make_dbsnp_link(rsid)
	"http://www.ncbi.nlm.nih.gov/projects/SNP/snp_ref.cgi?rs=#{rsid}"
end

def allele_strings_for_snp(snp)
	allele_strs = 
		snp.alleles.values.map do |allele|
			mapping_strs = 
				allele.mappings.values.map do |mapping|
					"#{mapping.symbol} #{mapping.function_class}"
				end

			"#{allele.sequence} (#{mapping_strs.join('; ')})"
		end

	allele_strs
end

def assay_to_alleles(snp, assay_id)
	# look up assay
	assay = snp.assays[assay_id]
	nil if !assay

	# puts assay.inspect

	# separate assay into individual calls
	assay.genotype.chars.map do |call|
		# puts call

		# convert call to allele
		case call
		when /[ATCG]/
			# standard snp
			# reorient call to other strand if snp's snp-to-chr orientation is reversed
			oriented_call = snp.orient ? call.complement : call

			snp.alleles[oriented_call]
		when 'I'
			# indel insertion
			# make sure there's a deletion allele
			nil if !snp.alleles["-"]
			# if > 2 alleles, actual allele is ambiguous
			nil if snp.alleles.count > 2

			# grab the allele that's not the deletion allele
			snp.alleles.find { |k, v| k != "-" }[1]
		when 'D'
			# indel deletion
			snp.alleles["-"]
		end
	end
end

# categorize all SNPs
merged_scope_snps.values.each do |snp|
	GROUPS.categorize(snp).snps << snp
end

f = File.open('report.html', 'w') do |f|
	html = Slim::Template.new('report.slim').
		render(nil, 
			   :groups => GROUPS,
			   :snps => merged_scope_snps,
			   :summary => summary,
			   :assay_id => ARGV[0])

	f.write html
end