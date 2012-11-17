# 23andme uses undocumented internal SNP IDs for a majority of the SNPs in
# their database, even those that have an assigned rs- or ss-id.  this program
# reads a list of raw SNP data in the 23andme download format, then creates
# an index of rs synonyms for each internal ID.

ARGV.length >= 1 or fail "Usage: get-rs-for-23andme [23andme output]"

