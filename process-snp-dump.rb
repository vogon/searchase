require 'set'

require './snpget'
require './parse-23andme-snp-dump'
require './alfred'

def allele_set_from_seq(alleles)
	allele_set = Set.new

	allele_set << :A if alleles =~ /A/
	allele_set << :C if alleles =~ /C/
	allele_set << :G if alleles =~ /G/
	allele_set << :T if alleles =~ /T/

	allele_set
end

def complement(base)
	case base
	when :A then :T
	when :C then :G
	when :G then :C
	when :T then :A
	end
end

def allele_list_from_call(call)
	call.chars.map { |ch| ch.to_sym }
end

ARGV.length >= 1 or fail "please pass a filename to process!"

# # load alfred ID database
# alfred_ids = load_alfred_id_db(ARGV[1])

# puts "loaded db of #{alfred_ids.count} ALFRED IDs..."

alfred_ids = {}

# read 23andme SNP dump to grab a list of SNPs.
all_snps = parse_23andme_snp_dump(ARGV[0])

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

# fetch information from entrez
called_snps.each do |id, snp|
	if alfred_ids[id] then
		id_string = "#{id} (#{alfred_ids[id]}): "
	else
		id_string = "#{id}: "
	end

	# get SNP data from entrez.
	entrez_snp = get_snp(snp.id)

	# get frequency elements from SNP data.
	freqs = entrez_snp.css('Rs > Frequency')

	if freqs.length == 0 then
		# no frequency data; skip.
		next
	elsif freqs.length == 1 then
		# frequency data.
		allele_string = entrez_snp.css('Rs > Sequence > Observed')[0].content
		alleles = allele_set_from_seq(allele_string)
		minor_freq = freqs[0]['freq'].to_f
		minor_allele = freqs[0]['allele'].to_sym

		if (alleles.count == 2) then
			# 2 known alleles; can compute probability directly.
			p = 1

			allele_list_from_call(snp.call).each do |allele|
				if minor_allele == allele then
					p *= minor_freq
				else
					p *= (1 - minor_freq)
				end
			end

			call_string = "(#{snp.call}; p=#{p})"
		else
			call_string = "(#{snp.call})"
		end

		# it appears that dbSNP incorrectly reports the minor allele in some cases as its
		# complement.  if it doesn't match any of the reported alleles, flip it and alert the
		# user.
		if alleles.member?(minor_allele) then
			puts "#{id_string} #{allele_string}; #{minor_allele}=#{minor_freq} #{call_string}" if (!p.nil? && p <= p_cutoff)
		else
			real_minor_allele = complement(minor_allele)
			puts "#{id_string} #{allele_string}; #{minor_allele}(#{real_minor_allele})=#{minor_freq} #{call_string}" if (!p.nil? && p <= p_cutoff)
		end
	else
		fail "weird number of frequencies"
	end
end