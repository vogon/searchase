def load_alfred_id_db(filename)
	f = open(filename)
	ids = {}

	f.each_line do |line|
		alfred_id, rsid = line.split(',')

		ids[rsid] = alfred_id
	end

	ids
end