class Moredirt < WebParser::Parser

	# TODO: extract text from pdf 
	# Manybooks.new(:threads_number => 5, :sitemap_from_file => true).parse_now
	




	def parse_now
		@types = [
			{:id=>"7", :title => "4X/Dual Slalom"},
			{:id=>"6", :title => "Bike Parks"},
			{:id=>"2", :title => "BMX Track"},
			{:id=>"5", :title => "Downhill"},
			{:id=>"3", :title => "Dirt Jumps"},
			{:id=>"8", :title => "Family Trail"},
			{:id=>"11", :title => "Freeride"},
			{:id=>"15", :title => "MTB Uplift"},
			{:id=>"13", :title => "Pump Track"},
			{:id=>"9", :title => "Skate Park"},
			{:id=>"12", :title => "Skills Area"},
			{:id=>"4", :title => "Cross Country (XC)"}
		]


		# http://www.moredirt.com/region/United-Kingdom/trails/?trail_type=0&sub_location_id=0&page=0
		@countries = [
			{:seo=> 'United-Kingdom', :title=>'United Kingdom'},
      {:seo=> 'United-States', :title=>'United States'},
      {:seo=> 'Canada', :title=>'Canada'},
      {:seo=> 'Andorra', :title=>'Andorra'},
      {:seo=> 'Australia', :title=>'Australia'},
      {:seo=> 'Austria', :title=>'Austria'},
      {:seo=> 'Belgium', :title=>'Belgium'},
      {:seo=> 'Bulgaria', :title=>'Bulgaria'},
      {:seo=> 'Croatia', :title=>'Croatia'},
      {:seo=> 'Czech-Republic', :title=>'Czech Republic'},
      {:seo=> 'Finland', :title=>'Finland'},
      {:seo=> 'France', :title=>'France'},
      {:seo=> 'Germany', :title=>'Germany'},
      {:seo=> 'Ireland', :title=>'Ireland'},
      {:seo=> 'Italy', :title=>'Italy'},
      {:seo=> 'New-Zealand', :title=>'New Zealand'},
      {:seo=> 'Norway', :title=>'Norway'},
      {:seo=> 'Poland', :title=>'Poland'},
      {:seo=> 'Portugal', :title=>'Portugal'},
      {:seo=> 'Romania', :title=>'Romania'},
      {:seo=> 'Singapore', :title=>'Singapore'},
      {:seo=> 'Slovakia', :title=>'Slovakia'},
      {:seo=> 'Slovenia', :title=>'Slovenia'},
      {:seo=> 'South-Africa', :title=>'South Africa'},
      {:seo=> 'Spain', :title=>'Spain'},
      {:seo=> 'Sweden', :title=>'Sweden'},
      {:seo=> 'Ukraine', :title=>'Ukraine'}
		]

    @trails = {}
    sitemap = WebParser::Sitemap.new
    @agent = Mechanize.new

    @countries.each do |c|
    	@types.each do |t|
				# urls = WebParser::Sitemap.get_site_urls 'http://www.moredirt.com/region/United-States/trails/?trail_type=0&sub_location_id=0&page=0', {:href =>/\/trail\/United-States/}, {:href =>/\/region\/United-States\/trails\/\?trail_type/}
				urls = sitemap.get_site_urls "http://www.moredirt.com/region/#{c[:seo]}/trails/?trail_type=#{t[:id]}&sub_location_id=0&page=0", {:href =>/\/trail\/#{c[:seo]}/}, {:href =>/\/region\/#{c[:seo]}\/trails\/\?trail_type/}
				urls.each do |url|
					if !@trails[url]
						data = get_trail_data url, c, t
						next if !data
						@trails[url] = data
					else
						@trails[url][:types] << t[:title]
					end
				end
			end
		end

		append("public/webparser/moredirt.com.json", @trails.to_json)	
		ap @trails.count
		ap @trails
		
	end			

	def get_trail_data url, country, type
		# page =  get_page 'http://www.moredirt.com/trail/Germany_Baden-Wurttemberg_Ulm/Hindelang-Bike-Park/958/', @agent
		puts url.green
		page =  get_page url, @agent, true
		html = page.first

		description_block = html.search('#description .panel-body')
		description = (description_block && description_block.first) ? description_block.first.text : ''

		how_to_get_block = html.search('#location .panel-body')
		how_to_get = (how_to_get_block && how_to_get_block.first) ? how_to_get_block.first.text.sub("View Larger Map", '') : ''
		how_to_get.sub!("Map not available", '')
		# how_to_get.sub!("\n\n", '')

		link_with_coords = how_to_get_block.search('a').first if how_to_get_block
		if link_with_coords
			link_with_coords.attributes['href'].to_s =~ /q=(.*?)&/
			return false if !$1
			coords = $1.split(',')
		end 
		if coords
			lat_lng = {:lat => coords[0].to_f, :lng => coords[1].to_f}
		else
			lat_lng = {:lat => 0, :lng => 0}
		end

		nearest_town = nil
		with_flags = html.search('p.flags')
		if with_flags
			with_flags.each do |p|
				next if p.search('strong').first && p.search('strong').first.text != 'Nearest Town:'
				nearest_town = p.text.sub('Nearest Town:', '').gsub(/[^0-9A-Za-z\- ]/, '').strip
				break
			end
		end

		site = nil
		tr = html.search('tr')
		if tr
			tr.each do |t|
				next if t.search('td')[0].nil? || t.search('td')[0].text.strip != 'Website:'
				site = t.search('td')[1].text.strip
				break
			end
		end
		
		{
			:title => html.search('h1').first.text.strip,
			:description => description.strip,
		  :how_to_get => how_to_get.strip,
			:country => country[:title],
			:nearest_town => nearest_town,
			:types => [type[:title]],
			:lat_lng => lat_lng,
			:site => site
		}
	end


# 	def parse_now
# 		parse 'http://manybooks.net/language.php', {:href =>/titles\//}, {:href =>/language.php\?code/}, {:href =>/language.php\?code/}
# 	end			
		
# 	def extract_data page
# 		data = {}
# 		data[:title] = page.search('.booktitle').text.strip
# 		descr_tag = page.search('.notes p')
# 		data[:description] = descr_tag.text.strip if descr_tag.present?
# # ap page.uri.path.split('/').last.split('.').pop.join('.')

# 		fields = page.search('.title-info')
# 		fields.each do |one|
# 			title = one.search('span')[0].text.split(':')[0].downcase
# 			case title
# 				when "author"
# 					data[:author_full] =  one.search('a')[0].text
# 					name_parts = data[:author_full].split(' ')
# 					data[:author_last] = name_parts.pop
# 					data[:author_first] = name_parts.join(' ')
# 				when "language"
# 					data[:language] =  one.search('a')[0].text.downcase
# 				when "genres"
# 					links = one.search('a')
# 					if links
# 						names = links.map{|l| l.text.downcase} 
# 						data[:genres_list] = names[0].capitalize
# 						data[:tags_list] = names.join('|')
# 					end
# 			end
# 		end
# 		# extract_text data, page, nil
# 		data
# 		# ap data
# 		# false
# 	end

# 	def extract_text data, page, agent

# 		# 1:pdf:.pdf:pdf
# 		# 1:text:.txt:text

# 		text_option = page.search('option[value="1:text:.txt:text"]')
# 		# text_option = page.search('option[value="1:pdf:.pdf:pdf"]') if !text_option.present?

# 			# ap text_option

# 		result = false
# 		# file_href = page.link_with(:text => 'Скачать в формате TXT')
# 		if text_option.present?


# 			id = page.uri.to_s.scan(/titles\/([^.]*).html/)[0][0]

# 			file_href = "http://manybooks.net/send/1:text:.txt:text/#{id}/#{id}.txt"
# 			# ap file_href

# 			# 

# 		# 	url = file_href.uri.to_s
# 		# agent = Mechanize.new
# 			file_body = get_file file_href, agent, true
# 			if file_body.present?
# 				# ap file_body
				
# 				file_body.sub!('A free ebook from http://manybooks.net/', "")
# 				file_body.sub!('from http://manybooks.net/', "")
# 				data.text = @html_entities.decode file_body
# 				data.save_text
# 				result = true 
# 			else
# 				@log[page.uri.to_s] << "no text, no txt files".red
# 			end
# 		else
# 			@log[page.uri.to_s] << "no text, no txt href".red
# 		end
# 		result
# 	end

	# def extract_img data, page, agent
	# 	img_tag = page.search('.cover-download-wrapper img')
	# 	img_url = img_tag[0].attribute('src').to_s
	# 	data.save_img(img_url) if img_url.split('/').last != "cover.jpg"
	# end

	# def encode str
	# 	begin
	# 		str.encode('UTF-8')
	# 	rescue Encoding::UndefinedConversionError
	# 		false
	# 	end
	# end

end

