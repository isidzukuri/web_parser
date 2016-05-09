class Singletrack < WebParser::Parser

	
	# Singletrack.new(:threads_number => 10, :sitemap_from_file => true).parse_now
	

	def parse_now
    @trails = []
    parse 'http://www.singletracks.com/mountain-bike/best_trails.php?page=1', {:href =>/\/bike-trails\//}

  #   sitemap = WebParser::Sitemap.new
  #   urls = []
		# i = 1
		# until i > 110  do
		# 	urls += sitemap.get_site_urls "http://www.singletracks.com/mountain-bike/best_trails.php?page=#{i}", {:href =>/\/bike-trails\//}
		# 	i +=1;
		# end
		# urls = urls.uniq
		# append("public/webparser/sitemap/www.singletracks.com/#{DateTime.now.strftime('%Y_%m_%d')}.json", urls.to_json)
		append("public/webparser/singletracks.com.json", @trails.to_json)	
		ap @trails
		ap @trails.count
	end			

	def parse_one url, agent
		page =  get_page url, agent, false
		return if !page || !page.first
		html = page.first

		description_block = html.search('#st_description')
		description = (description_block && description_block.first) ? description_block.first.text : ''

		country = nil
		region = nil
		nearest_town = nil

		breadcrumps = html.search('#st_breadcrumb')
		return false if !breadcrumps
		if breadcrumps && links = breadcrumps.search('a')
			return false if links[1].nil?
			country = links[1].text.strip
			nearest_town = links[(links.count-2)].text.strip
			region = links[2].text.strip if links.count == 5
		end

		lat_lng = nil
		block_with_coords = html.search('#st_directions_block')
		if block_with_coords && text = block_with_coords.search('#st_directions_block').first.text
			raw_json = text[/\[{(.*?)}\]/]
			if raw_json
				coords = nil
				markers = JSON.parse raw_json
				markers.each do |marker|
					if marker["name"] == 'Trailhead'
						coords = marker
						break
					end
				end
				coords = markers[0] if !coords
				lat_lng = {:lat => coords['lat'].to_f, :lng => coords['lon'].to_f}
			end
		end

		distance = nil
		colls = html.search('.st_stat1')
		if colls
			colls.each do |div|
				next if !div.search('[style="st_stat_minor"]').first || div.search('[style="st_stat_minor"]').first.text != 'miles'
				distance = (div.search('.st_stat_major').first.text.to_i * 1.60934).to_i
				break
			end
		end

		return false if !lat_lng
		
		@trails << {
			:title => html.search('h1').first.text.strip,
			:description => description.strip,
			:country => country,
			:region => region,
			:nearest_town => nearest_town,
			:types => ['mtb'],
			:distance => distance,
			:lat_lng => lat_lng,
			:source => url
		}
	end

end

