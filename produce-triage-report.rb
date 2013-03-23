require 'tilt'
require 'slim'

require './snp'
require './load-23andme'
require './load-dbsnp'

class Rule
	private
	DEFAULT_MATCHER = Proc.new { |snp, assay| true }
	DEFAULT_SCORER = Proc.new { |snp, assay, prev_score| prev_score }

	public
	def initialize(name)
		self.name = name
		self.match_fn = DEFAULT_MATCHER
		self.score_fn = DEFAULT_SCORER

		yield self if block_given?
	end

	def score_assay(snp, assay, prev_score)
		if self.match_fn.(snp, assay) then
			self.score_fn.(snp, assay, prev_score)
		else
			prev_score
		end
	end

	attr_accessor :name
	attr_accessor :match_fn, :score_fn
end

def noisy_mutation?(mapping)
	!!([
		"missense",
		"stop-gained",
		"stop-lost",
		"frameshift-variant",
		"cds-indel"
	].index(mapping.function_class))
end

RULES =
	[
		Rule.new("assay calls all non-reference alleles") do |rule|
		end,

		Rule.new("assay calls at least one noisy mutation") do |rule|
			rule.match_fn = Proc.new do |snp, assay|
				assay_alleles = assay_to_alleles(snp, assay)

				assay_alleles.any? do |allele|
					# puts allele.mappings.inspect
					# bomb out early if no call
					if !allele then
						false
						break
					end

					allele.mappings.values.any? do |mapping|
						noisy_mutation?(mapping)
					end
				end
			end

			rule.score_fn = Proc.new { |snp, assay, prev_score| prev_score + 100 }
		end,

		Rule.new("SNP is known to be pathogenic") do |rule|
			rule.match_fn = Proc.new do |snp|
				snp.clinical_significance == 'pathogenic'
			end

			rule.score_fn = Proc.new { |snp, assay, prev_score| prev_score + 10 }
		end,

		Rule.new("SNP has an allele associated with a gene") do |rule|
			rule.match_fn = Proc.new do |snp|
				snp.alleles.values.any? { |allele| allele.mappings != {} }	
			end

			rule.score_fn = Proc.new { |snp, assay, prev_score| prev_score + 5 }
		end
	]

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
					"#{mapping.symbol} #{mapping.function_class} #{mapping.so_term}"
				end

			"#{allele.sequence} (#{mapping_strs.join('; ')})"
		end

	allele_strs
end

def assay_to_alleles(snp, assay)
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

def assay_id_to_alleles(snp, assay_id)
	assay = snp.assays[assay_id]
	nil if !assay

	assay_to_alleles(snp, assay)
end

# score all SNPs
scored_snps = merged_scope_snps.values.map do |snp|
	assay = snp.assays[ARGV[0]]

	score = RULES.reduce(0) do |memo, rule|
		rule.score_assay(snp, assay, memo)
	end

	{ snp: snp, score: score }
end

scored_snps.sort! do |snp_a, snp_b|
	snp_b[:score] <=> snp_a[:score]
end

f = File.open('report.html', 'w') do |f|
	html = Slim::Template.new('report.slim').
		render(nil, 
			   :scored_snps => scored_snps,
			   :summary => summary,
			   :assay_id => ARGV[0])

	f.write html
end