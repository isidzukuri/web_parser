class TrailforksParks < WebParser::Parser

	
	# TrailforksParks.new(:threads_number => 10, :sitemap_from_file => true).parse_now
	

	def parse_now
		@parks = []

		@difficulties = {
			'easy' => ['Green', 'White', 'Access Road/Trail'],
			'moderate' => ['Blue', 'Secondary Access Road/Trail '],
			'difficult' => ['Black', 'Black Diamond', 'Proline'],
			'pro' => ['Double Black Diamond']
		}

		parse 'http://www.trailforks.com/bikeparks/?page=1', {:href =>/region\//}, {:href =>/bikeparks\/\?/}
		append("public/webparser/#{@host}_parks.json", @parks.to_json)	
		ap @parks
		ap @parks.count
	end	
		

	def parse_one url, agent

		page =  get_page url, agent, true
		return if !page || !page.first
		html = page.first
		folder = url.split('/').last.gsub(/[^A-Za-z]/, '')

		source = url

		description = ''
		description_block = html.search('#region_description')	
		if description_block && (desc = description_block.first)
			description = Sanitize.fragment(desc.inner_html, :elements => ['b','ul','ol','li','p','br']).strip
		end


		title = ''
		title_block = html.search('#regiontitle')	
		if title_block && (title = title_block.first)
			title = title.text.to_s.strip
		end


		logo_block = html.search('#region_area2 .col-3 a img')
		if logo_block && (logo_item = logo_block.first)
			logo_src = logo_item.attribute('src').to_s
			save_file logo_src, "#{folder}/logo", agent
		end


		trail_difficulty = {}
		
		tr = html.search('#region_area2 .col-3 .stats .dicon_small')
		if tr
			tr.each_with_index do |t, i|
				key = t.attribute('title').to_s.strip
				difficulty = nil
				@difficulties.each do |k, synonyms|
					if synonyms.include?(key)
						difficulty = k 
						break
					end
				end
				next if !difficulty
				if !trail_difficulty[difficulty.to_sym]
					trail_difficulty[difficulty.to_sym] = html.search('#region_area2 .col-3 .stats .stat-num')[i].text.strip.to_i
				else
					trail_difficulty[difficulty.to_sym] += html.search('#region_area2 .col-3 .stats .stat-num')[i].text.strip.to_i
				end
			end
		end

		lat,lng,site = nil
		if lat_block = html.at('meta[property="place:location:latitude"]')
			lat = lat_block.attribute('content').to_s.to_f
		end
		if lng_block = html.at('meta[property="place:location:longitude"]')
			lng = lng_block.attribute('content').to_s.to_f
		end

		breadcrumps = html.search('.breadcrumb')
		return false if !breadcrumps
		if breadcrumps && links = breadcrumps.search('a')
			return false if links[1].nil?
			country = links[0].text.strip
			settlement = links[(links.count-2)].text.strip
		end


		@parks << {
			:title => title,
			:description => description,
			:lat => lat,
			:lng => lng,
			:settlement => settlement.strip,
			:country => country.strip,
			:trail_difficulty => trail_difficulty,
			:folder => folder,
			:source => source
		}

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

