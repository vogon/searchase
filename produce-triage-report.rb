require 'tilt'
require 'slim'

require './snpcall'
require './snpcall-23andme'
require './snp'
require './snp-dbsnp'

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
			snp.genes != []
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

snp_calls = SNPCall.load_23andme_dump(ARGV[0])
summary[:total_count] = snp_calls.count

scope_snp_calls = snp_calls.select { |id, snp| CONFIG[:in_scope?].(snp) }
summary[:scope_count] = scope_snp_calls.count

scope_snps = {}

i = 0

scope_snp_calls.keys.each do |rsid|
	print "#{i}..." if i % 100 == 0

	scope_snps[rsid] = SNP.load_dbSNP(rsid)

	i = i + 1
end

puts

DbSNP.flush

def make_dbsnp_link(rsid)
	"http://www.ncbi.nlm.nih.gov/projects/SNP/snp_ref.cgi?rs=#{rsid}"
end

def gene_string_for_snp(snp)
	genes = {}

	snp.alleles.values.each do |allele|
		allele.mappings.each do |mapping|
			gene = mapping.gene

			genes[gene] = {} if !genes[gene]
		end
	end

	str = ""

	genes.keys.each do |gene|
		str << "#{gene.symbol} (#{gene.coding_strand}), "
	end

	str
end

# categorize all SNPs
scope_snps.values.each do |snp|
	GROUPS.categorize(snp).snps << snp
end

f = File.open('report.html', 'w') do |f|
	html = Slim::Template.new('report.slim').
		render(nil, 
			   :groups => GROUPS,
			   :snp_calls => scope_snp_calls,
			   :snps => scope_snps,
			   :summary => summary)

	f.write html
end