# crunch down an Illumina CSV manifest to the data we want

require 'yaml'

ARGV.length >= 3 or fail "provide a params file and manifest file"

params_file = ARGV[0]
manifest_file = ARGV[1]
output_file = ARGV[2]

load params_file

File.open(manifest_file) do |io_in|
	# skip stuff until we hit the assay section
	until io_in.readline =~ /\[Assay\]/ do
	end

	header = io_in.readline
	columns = header.split(",")
	column_index = columns.index(PARAMS[:column_name])

	fail "column not found" if !column_index

	rows_selected = 0
	
	# line after the assay: check for the requested column name
	File.open(output_file, 'w') do |io_out|
		io_out.puts header

		loop do
			line = io_in.readline
			puts line if line.length < 40
			# read until the next section
			if line =~ /^\[/ then
				puts "oop"
				break
			end

			# check for a requested value
			column_value = line.split(',')[column_index]

			if PARAMS[:column_values].any? { |val| val == column_value } then
				io_out.puts line
				rows_selected += 1
			end
		end
	end

	puts "#{rows_selected} rows selected."
end