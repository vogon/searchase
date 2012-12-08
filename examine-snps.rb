require 'irb'
require 'yaml'

require './snpget'

# load YAML produced by process-snp-dump
fail if ARGV.length < 1
yaml_name = ARGV[0]

SNP = YAML.load_file(yaml_name)

# here are some methods you can use to examine it
def SNP.order_by_probability
	SNP.values.select {|snp| snp[:p]}.sort {|snp1, snp2| snp1[:p] <=> snp2[:p]}
end

def SNP.pathogenic
	pathogenic_snps = []

	SNP.values.each do |snp|
		rsid = snp[:id]

		# get the entrez data for the SNP, then check out the clinical significance data
		entrez_snp = get_snp(rsid)

		clinical_significance = entrez_snp.css('Rs ClinicalSignificance').text
		SNP[rsid][:clinical_significance] = clinical_significance

		pathogenic_snps << snp if clinical_significance == 'pathogenic'
	end

	pathogenic_snps
end

# fire up irb in this environment
ARGV.clear
IRB.start