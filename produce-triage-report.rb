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

		if block_given? then
			yield self
		end

		fail if (self.name.nil? || self.predicate.nil?)
	end

	attr_accessor :name, :predicate
end

class GroupChain
	def initialize
		@chain = []

		yield self
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
		g.name = 'blah'
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

f = File.open('report.html', 'w') do |f|
	html = Slim::Template.new('report.slim').
		render(nil, 
			   :snp_calls => scope_snp_calls,
			   :snps => scope_snps,
			   :summary => summary)

	f.write html
end