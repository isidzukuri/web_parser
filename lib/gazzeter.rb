class Gazzeter < WebParser::Parser

	# Royallib.new(:threads_number => 5, :sitemap_from_file => true).parse_now
	
	def parse_now
		agent = Mechanize.new
		page =  get_page 'http://archive.is/20121210043906/http://www.world-gazetteer.com/wg.php?x=1120760399&men=gcis&lng=en&gln=xx&dat=32&geo=-220&srt=1npn&col=aohdq&pt=c&va=x#selection-9319.3-9323.7', agent
		

		rows = page[0].search('tr')
		# ap rows
		td = 1
		data = []
		rows.each do |r|
			td = r.search('td')
			if td.length == 8
				row_text = []

				settlment_data = {}

				td.each_with_index do |d, i|
					settlment_data['en'] = d.text if i == 1
					settlment_data['uk'] = d.text if i == 2
					settlment_data['r'] = d.text if i == 7
					# row_text << td.text
				end
				# ap row_text.join(' ')
				data << settlment_data

			end

		end
		append("public/webparser/ukrainian_settlements.json", data.to_json)	
		regions = []
		cities = []
		ap data
		
	end			
		
	

end

