f = open(ARGV[0])

line_number = 0

f.each_line do |line|
	line_number += 1

	if line =~ /#/ then
		# puts "ignored comment"
		next
	end

	fields = line.split("\t")

	if !(fields[0] =~ /^rs/) then
		# puts "ignored non-rs SNP"
		next
	end

	if !(fields[3] =~ /^[ATCG]/) then
		# puts "ignored SNP with unexpected call #{fields[3]}"
		next
	end

	puts "#{line_number}: #{fields[0]} = #{fields[3]}"
end