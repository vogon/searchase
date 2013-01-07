require 'tilt'
require 'slim'

require './snpcall'
require './snpcall-23andme'

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

ARGV.length >= 1 or fail "specify a SNP dump file"

summary = {}

snps = SNPCall.load_23andme_dump(ARGV[0])
summary[:total_count] = snps.count

rs_snps = snps.select { |id, snp| snp.id.rsid? }
summary[:rsid_count] = rs_snps.count

called_snps = rs_snps.select { |id, snp| snp.call.called? }
summary[:called_count] = called_snps.count

f = File.open('report.html', 'w') do |f|
	f.write (Slim::Template.new('report.slim').render(nil, :snps => called_snps, :summary => summary))
end