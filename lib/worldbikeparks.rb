class Worldbikeparks < WebParser::Parser

	
	# Worldbikeparks.new(:threads_number => 10, :sitemap_from_file => true).parse_now
	

	def parse_now
    @parks = []

		@difficulties = {
			'easy' => ['Easy', 'Easiest', 'Beginner', 'XC', 'Very', 'Light'],
			'moderate' => ['Moderate', 'More Difficult', 'Intermediate', 'Medium', 'All mtn', 'Light'],
			'difficult' => ['Difficult', 'Most Difficult', 'Expert', 'Advanced', 'Very Difficult', 'DH'],
			'pro' => ['Pro', 'Expert Only', 'Expert', 'Extreme', 'Extremely Difficult', 'Ex. Difficult', 'Expert / Pro', 'Professional', 'Most Advanced', 'Expert   Pro', 'Freeride', 'Hard', 'Ex Difficult']
		}
    parse 'http://www.worldbikeparks.com/locator', '.locator-markers li a'
		append("public/webparser/#{@host}.json", @parks.to_json)	
		ap @parks
		ap @parks.count
	end			

	def parse_one url, agent
		page =  get_page url, agent, true
		return if !page || !page.first
		html = page.first
		folder = url.split('/').last.gsub(/[^A-Za-z]/, '')

		source = url
		videos = []

		description = ''
		description_block = html.search('#ContentPlaceHolder_Main_ContentPlaceHolder_ParkPage_Panel_Introduction')	
		if description_block && (desc = description_block.first)
			iframes = desc.search('iframe')
			iframes.map{|ifr| videos << ifr.attribute('src').to_s.gsub(/\A\/\//, '')} if iframes
			description = Sanitize.fragment(desc.inner_html, :elements => ['b','a','ul','ol','li','p','br'], :attributes => {'a'=> ['href', 'target']}).strip
		end

		title = ''
		logo_block = html.search('#ContentPlaceHolder_Main_Image_Logo')
		if logo_block && (logo_item = logo_block.first)
			title = logo_item.attribute('alt').to_s.strip

			logo_src = "http://#{@host}#{logo_item.attribute('src').to_s}"
			save_file logo_src, "#{folder}/logo", agent
		end


		# pdf_block = html.search('#ContentPlaceHolder_Main_Panel_RelatedDocs a')
		# if pdf_block && (pdf_a = pdf_block.first)
		# 	pdf_src = "http://#{@host}#{pdf_a.attribute('href').to_s.strip}"
		# 	save_file pdf_src, "#{folder}/trails_map", agent, 'park_map.pdf'
		# end

		category = html.search('#ContentPlaceHolder_Main_Image_CategoryIcon').attribute('alt').to_s.strip

		uplift = []
		if uplift_block = html.search('#parkUpliftIcons img')
			uplift = uplift_block.map{|it| it.attribute('alt').to_s}
		end

		trail = []
		if trail_block = html.search('#parkTrailsIcons img')
			trail = trail_block.map{|it| it.attribute('alt').to_s}
		end

		trail_difficulty = {}
		
		tr = html.search('#trailTable tr')
		if tr
			tr.each do |t|
				key = t.search('td')[0].text.strip.gsub(/[^A-Za-z ]/, '').strip
				next if key == "NA"
				difficulty = nil
				@difficulties.each do |k, synonyms|
					if synonyms.include?(key)
						difficulty = k 
						break
					end
				end
				next if !difficulty
				if !trail_difficulty[difficulty.to_sym]
					trail_difficulty[difficulty.to_sym] = t.search('td')[1].text.strip.to_i
				else
					trail_difficulty[difficulty.to_sym] += t.search('td')[1].text.strip.to_i
				end
			end
		end

		lat,lng,tel,email,site = nil
		if lat_block = html.search('#ContentPlaceHolder_Main_ContentPlaceHolder_ParkPage_HiddenField_Latitude')
			lat = lat_block.attribute('value').to_s.to_f
		end
		if lng_block = html.search('#ContentPlaceHolder_Main_ContentPlaceHolder_ParkPage_HiddenField_Longitude')
			lng = lng_block.attribute('value').to_s.to_f
		end

		if tel_block = html.search('#ContentPlaceHolder_Main_Panel_Tel')
			tel = tel_block.text.sub('Tel.', '').strip
		end

		if (email_block = html.search('#ContentPlaceHolder_Main_Panel_Email a')) && email_block.first
			email = email_block.first.text.strip
		end

		if (site_block = html.search('#ContentPlaceHolder_Main_Panel_Web a')) && site_block.first
			site = site_block.first.attribute('href').to_s
		end

		settlement, country = html.search('h1').first.text.split('/')


		page =  get_page "#{url}/media", agent, true
		return if !page || !page.first
		html = page.first

		if (videos_hrefs = html.search('#dvideos a')) && videos_hrefs.first
			videos_hrefs.map{|v| videos << v.attribute('href').to_s.gsub(/\A\/\//, '')}
		end

		if (photos = html.search('.am-container img')) && photos.first
			photos.each do |p|
				photo_src = "http://#{@host}#{p.attribute('src').to_s.gsub('thumb1','main')}"
				save_file photo_src, "#{folder}/photos", agent
			end
		end

		@parks << {
			:title => title,
			:description => description,
			:lat => lat,
			:lng => lng,
			:tel => tel,
			:email => email,
			:site => site,
			:settlement => settlement.strip,
			:country => country.strip,
			:category => category,
			:uplift => uplift,
			:trail => trail,
			:trail_difficulty => trail_difficulty,
			:videos => videos.uniq,
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

