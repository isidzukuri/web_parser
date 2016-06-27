class TrailforksTrails < WebParser::Parser

	
	# TrailforksTrails.new(:threads_number => 10, :sitemap_from_file => true).parse_now
	

	def parse_now
		@c = 0;
		@trails = []

		@difficulties = {
			'easy' => ['Green', 'White', 'Access Road/Trail'],
			'moderate' => ['Blue', 'Secondary Access Road/Trail', 'Red'],
			'difficult' => ['Black', 'Black Diamond', 'Proline', 'Advanced'],
			'pro' => ['Double Black Diamond']
		}

		@types = {
			"mtb" => ['Fat'],
			"4X/Dual Slalom" => [],
			"BMX Track" => [],
			"Downhill" => ['DH'],
			"Dirt Jumps" => ['DJ'],
			"Freeride" => [],
			"Pump Track" => [],
			"Skate Park" => [],
			"Skills Area" => [],
			"Cross Country (XC)" => ['XC'],
			"Bike Parks" => [],
			"Family Trail" => ['RD'],
			"MTB Uplift" => [],
			"Enduro" => ['AM'],
		}

		parse 'http://www.trailforks.com/trails/all/top/?difficulty=2,3,4,5,6,8,9,10,11&t.trackid=%3E0&global_rank=%3E0&page=1', {:href =>/trails\//}, {:href =>/trails\/all\/top\/\?difficulty=2,3,4,5,6,8,9,10,11&global_rank=>0&page=/}
		# append("public/webparser/#{@host}_trails.json", @trails.to_json)	
		ap @trails
		ap @trails.count
		return true
	end	


	def parse_one url, agent
		
		# return if @c >= 50643
	# @trails = []

	# @difficulties = {
	# 	'easy' => ['Green', 'White', 'Access Road/Trail'],
	# 	'moderate' => ['Blue', 'Secondary Access Road/Trail', 'Red'],
	# 	'difficult' => ['Black', 'Black Diamond', 'Proline', 'Advanced'],
	# 	'pro' => ['Double Black Diamond']
	# }

	# @types = {
	# 	"mtb" => ['Fat'],
	# 	"4X/Dual Slalom" => [],
	# 	"BMX Track" => [],
	# 	"Downhill" => ['DH'],
	# 	"Dirt Jumps" => ['DJ'],
	# 	"Freeride" => [],
	# 	"Pump Track" => [],
	# 	"Skate Park" => [],
	# 	"Skills Area" => [],
	# 	"Cross Country (XC)" => ['XC'],
	# 	"Bike Parks" => [],
	# 	"Family Trail" => ['RD'],
	# 	"MTB Uplift" => [],
	# 	"Enduro" => ['AM'],
	# }
	# url = "http://www.trailforks.com/trails/world-cup-17982/"
	# agent = Mechanize.new



		page =  get_page url, agent, true
		return if !page || !page.first
		html = page.first
		folder = url.split('/').last.gsub(/[^A-Za-z]/, '')
		source = url
# return html

# ap url
		title = ''
		title_block = html.search('#trailtitle')	
		return if !title_block.present?
		if title_block && (title = title_block.first)
			title = title.text.to_s.strip
		end


		description = ''
		description_block = html.search('#trail_description')	
		if description_block && (desc = description_block.first)
			description = Sanitize.fragment(desc.inner_html, :elements => ['b','ul','ol','li','p','br']).strip
		end


		gpx_data = nil
		block_with_coords = html.search('#trail_area1')
		if block_with_coords && (text = block_with_coords.search('script')) && text.present?
			code = text.first.text.gsub(",                        ", '').gsub("\n                        ", '')[/\[{id(.*?)}\]/]
			gpx_data = eval(code) if code.present?
		end


		trail_difficulty, park_title = ''
		trail_types = []
		tr = html.search('#traildetails_display li')
		if tr
			tr.each do |t|
				tr_title = t.search('.term')[0].text.split(':')[0]
				case tr_title
					when "Riding area"
						park_title = t.search('.definition')[0].text.to_s.strip
					when "Difficulty rating"
						key = t.search('.definition')[0].text.to_s.strip
						@difficulties.each do |k, synonyms|
							if synonyms.include?(key)
								trail_difficulty = k 
								break
							end
						end
					when "Bike type"
						t.search('.definition')[0].text.to_s.strip.split(',').each do |key|
							@types.each do |k, synonyms|
								if synonyms.include?(key.strip)
									trail_types << k 
									break
								end
							end
						end
				end #case
			end
		end


		distance, climb, descent, avg_time = ''
		tr = html.search('#basicTrailStats .col-3')
		if tr
			tr.each do |t|
				tr_title = t.search('.small')[0].text
				case tr_title
					when "Distance"
						distance = t.search('.large').text.gsub(/[^\d]/, '')
					when "Climb"
						climb = t.search('.large').text.gsub(/[^\d]/, '')
					when "Descent"
						descent = t.search('.large').text.gsub(/[^\d]/, '')
					# when "Avg time"						
					# 	avg_time = t.search('.large').text.gsub(/[^\d]/, '')
				end #case
			end
		end


		lat,lng = nil
		if lat_block = html.at('meta[property="place:location:latitude"]')
			lat = lat_block.attribute('content').to_s.to_f
		end
		if lng_block = html.at('meta[property="place:location:longitude"]')
			lng = lng_block.attribute('content').to_s.to_f
		end

		breadcrumps = html.search('.breadcrumb')
		return false if !breadcrumps || !lat || !lng || !title || title == ''
		if breadcrumps && links = breadcrumps.search('a')
			return false if links[1].nil?
			country = links[0].text.strip
			settlement = links[(links.count-2)].text.strip
		end


		item = {
			:title => title,
			:description => description,
			:lat => lat,
			:lng => lng,
			:settlement => settlement.strip,
			:country => country.strip,
			:source => source,
			:trail_difficulty => trail_difficulty,
			:trail_types => trail_types,
			:distance => distance,
			:climb => climb,
			:descent => descent,
			:park_title => park_title,
			:gpx_data => gpx_data,
		}
		@trails << item 

		@c += 1
		append("public/webparser/#{@host}/trails/#{@c}.json", item.to_json)	
		@c
	end


	def save_file url, folder, agent, file_name = nil
		begin
			file = agent.get(url)
			file_name = url.split('/').last if !file_name
			file.save("public/webparser/#{@host}/#{folder}/#{file_name}") if file.present?
		rescue 
		end
	end



end

