require 'set'

require './snpget'
require './snpcall'
require './snpcall-23andme'
require './alfred'

def base_set_from_seq(bases)
	base_set = Set.new

	base_set << :A if bases =~ /A/
	base_set << :C if bases =~ /C/
	base_set << :G if bases =~ /G/
	base_set << :T if bases =~ /T/

	base_set
end

def seq_from_base_set(bases)
	s = ""

	bases.each do |base|
		s << "/" if !s.empty?
		s << base.to_s
	end

	s
end

def complement(base)
	case base
	when :A then :T
	when :C then :G
	when :G then :C
	when :T then :A
	else fail "unexpected base"
	end
end

def allele_list_from_call(call)
	call.chars.map { |ch| ch.to_sym }
end

# yes this is a slow implementation, no I don't care
def factorial(n)
	return 1 if n <= 1
	n * factorial(n - 1)
end

def choose(n, k)
	factorial(n) / (factorial(k) * factorial(n - k))
end

ARGV.length >= 1 or fail "please pass a filename to process!"

# # load alfred ID database
# alfred_ids = load_alfred_id_db(ARGV[1])

# puts "loaded db of #{alfred_ids.count} ALFRED IDs..."

alfred_ids = {}

# read 23andme SNP dump to grab a list of SNPs.
all_snps = SNPCall.load_23andme_dump(ARGV[0])

puts "loaded list of #{all_snps.length} SNPs..."

# remove all internal (non-"rs*" ID-ed) and uncalled (non-ATCG call) SNPs from list
called_snps = all_snps.select { |id, snp| snp.id =~ /^rs/ && snp.call =~ /^[ATCG]+$/ }

puts "extracted list of #{called_snps.length} called, public SNPs..."

# select a particular chromosome if one was specified
if ARGV.length >= 3 then
	chromosome = ARGV[2]

	called_snps = called_snps.select { |id, snp| snp.chr == chromosome }

	puts "extracted list of #{called_snps.length} SNPs on chromosome #{chromosome}..."
end

if ARGV.length >= 4 then
	p_cutoff = ARGV[3].to_f
else
	p_cutoff = 1
end

merged_data = {}

n = called_snps.length
n_complete = 0
n_known_freq = 0
n_known_prob = 0
n_10pct = 0
n_5pct = 0
n_1pct = 0

print "\n"

# fetch information from entrez
called_snps.each do |id, snp|
	print "\r#{n_complete}/#{n} (freq? #{n_known_freq}, p? #{n_known_prob}, <10% #{n_10pct}, <5% #{n_5pct}, <1% #{n_1pct})"
	STDOUT.flush

	# if alfred_ids[id] then
	# 	id_string = "#{id} (#{alfred_ids[id]})"
	# else
	# 	id_string = "#{id}"
	# end

	# get SNP data from entrez.
	entrez_snp = get_snp(snp.id)

	# get frequency elements from SNP data.
	freqs = entrez_snp.css('Rs > Frequency')

	n_complete += 1

	if freqs.length == 0 then
		# no frequency data; skip.
		next
	elsif freqs.length == 1 then
		# frequency data.
		n_known_freq += 1

		refseq_allele_string = entrez_snp.css('Rs > Sequence > Observed')[0].content
		refseq_alleles = base_set_from_seq(refseq_allele_string)

		called_alleles = allele_list_from_call(snp.call)

		# sometimes the alleles specified in the reference sequence are on the noncoding strand;
		# if the called alleles aren't part of the refseq allele set, assume this is the case
		# and complement it [the correct solution probably involves maploc orientations and a
		# bunch of other crap I don't want to mess around with]
		if called_alleles.any? { |base| !(refseq_alleles.member? base) } then
			alleles = Set.new
			refseq_alleles.each { |base| alleles << complement(base) }

			fail "uh something weird is going on here (#{id})" if called_alleles.any? { |base| !(alleles.member? base) }
		else
			alleles = refseq_alleles
		end

		minor_freq = freqs[0]['freq'].to_f
		minor_allele = freqs[0]['allele'].to_sym

		if (alleles.count == 2) then
			# 2 known alleles; can compute probability from minor allele frequency.
			n_known_prob += 1

			# number of chromosomes at the SNP location.
			ploidy = called_alleles.length

			# number of copies of the minor allele at the SNP location.
			minor_count = called_alleles.count { |base| base == minor_allele }

			# the probability of a given zygosity for this trait is:
			#   (the probability of having minor_count copies of the minor allele) *
			#   (the probability of having (ploidy - minor_count) copies of the major allele) *
			#   (the number of combinations (ploidy)C(minor_count), as being CT is the same as TC)
			p = (minor_freq ** minor_count) * ((1 - minor_freq) ** (ploidy - minor_count)) * choose(ploidy, minor_count)

			n_10pct += 1 if p <= 0.10
			n_5pct += 1  if p <= 0.05
			n_1pct += 1  if p <= 0.01

			merged_data[snp.id] = { :id => snp.id, :call => snp.call, :p => p }

			#call_string = "(#{snp.call}; p=#{p.round(4)})"
		else
			merged_data[snp.id] = { :id => snp.id, :call => snp.call }

			#call_string = "(#{snp.call})"
		end

		# puts "#{id_string}: #{seq_from_base_set(alleles)}; #{minor_allele}=#{minor_freq} #{call_string}" if (p.nil? || p <= p_cutoff)
	else
		fail "weird number of frequencies"
	end
end

print "\n"

if chromosome then
	merged_filename = "#{File.basename(ARGV[0], '.txt')} chr#{chromosome} #{DateTime.now.strftime('%Y%m%d %H%M%S')}.yaml"
else
	merged_filename = "#{File.basename(ARGV[0], '.txt')} #{DateTime.now.strftime('%Y%m%d %H%M%S')}.yaml"
end

require 'yaml'

File.open(merged_filename, 'w') do |f|
	YAML.dump(merged_data, f)
end