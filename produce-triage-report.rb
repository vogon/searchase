require 'tilt'
require 'slim'

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

f = File.open('report.html', 'w') do |f|
	f.write (Slim::Template.new('report.slim').render)
end