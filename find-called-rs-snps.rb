require './parse-23andme-snp-dump'

snps = parse_23andme_snp_dump(ARGV[0])

snps.select { |id, snp| snp.id =~ /^rs/ && snp.call =~ /^[ATCG]$/ }.each do |id, snp|
	print "#{snp.id} = #{snp.call}"
end