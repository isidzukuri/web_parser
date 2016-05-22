module WebParser
	class Sitemap < Initializator
		include PageParser, ThreadLock, WorkWithFiles
		attr_reader :urls, :agent, :host

		def get_urls_queue url, item_attr, paginator_attr, category_attr = nil, from_file = nil
			set_host(url)
			urls = from_file ? get_site_urls_from_file() : get_site_urls(url, item_attr, paginator_attr, category_attr)
			SimpleQueue.new(urls)
		end

		def get_site_urls_from_file
			files_sorted_by_time = Dir["public/webparser/sitemap/#{@host}/*"].sort_by{ |f| File.mtime(f) }
			JSON.parse open(files_sorted_by_time.first).read
		end

		def set_host url
			uri = URI.parse(url)
			@scheme = uri.scheme
			@host = uri.host.downcase
		end
		
		def get_site_urls start_url, item_attr, paginator_attr = nil, category_attr = nil
			puts "Searching for links".black.on_light_green
			set_host(start_url) if !@host
			@urls = []
			@agent = Mechanize.new

			if category_attr
				puts "get_urls_from_categories".black.on_light_green
				pages_with_paginator, agent = get_urls_from_categories(start_url, category_attr)
				ap pages_with_paginator

				urls = []
				pages_with_paginator.each do |item|
					urls += get_urls_from_paginator(item, paginator_attr, agent)
				end
				urls.uniq!
			elsif paginator_attr
				puts "get_urls_from_paginator".black.on_light_green
				urls = get_urls_from_paginator(start_url, paginator_attr)
			else
				urls = [start_url]
			end
			@url_queue = SimpleQueue.new(urls, @lock)

			puts "searching links".black.on_light_green
			threads = []
			@threads_number.times do 
				threads << Thread.new do
					parse_page_for_urls(@url_queue.next_item, item_attr)
				end
			end
			threads.each { |thr| thr.join }
			puts "#{@urls.count} links found".green
			save_urls(@urls)
			@urls
		end

		def parse_page_for_urls url, item_attr, agent = nil
			urls = []
			if url
				agent = Mechanize.new if !agent
				urls, agent = urls_from_page_by_attribute(url, item_attr, agent) 
				thread_lock.synchronize do
					puts "#{url} searching links".green
					@urls |= urls
				end
				parse_page_for_urls(@url_queue.next_item, item_attr, agent)
			end
			[urls, agent]
		end

		def urls_from_page_by_attribute url, attribute, agent = nil, use_cache = nil
			use_cache = use_cache.nil? ? @use_cache : use_cache
			urls = []
			page, agent = get_page(url, agent, use_cache)
			links = attribute.is_a?(Hash) ? page.links_with(attribute) : page.search(attribute)
			if links
				urls = links.map do |l| 
					if attribute.is_a?(Hash)
						l.href.include?(@host) ? l.href : "#{@scheme}://#{@host}#{l.href}"
					else
						href = l.attribute('href').to_s
						href.include?(@host) ? href : "#{@scheme}://#{@host}#{href}"
					end
				end
			end
			[urls, agent]
		end

		def get_urls_from_paginator url, attribute, agent = nil
			puts "#{url} checking paginator".green
			@paginator_urls ||= [url]
			@parsed_urls ||= []
			urls, agent = urls_from_page_by_attribute(url, attribute, agent) 
			@paginator_urls |= urls if urls	
			@parsed_urls << url
			to_parse = @paginator_urls - @parsed_urls
			to_parse.each do |url|
				break if @parsed_urls.include? url
				get_urls_from_paginator(url, attribute, agent)
			end
			@paginator_urls
		end

		def get_urls_from_categories url, attribute, agent = nil
			puts "#{url} checking categories".green
			urls_from_page_by_attribute(url, attribute, agent)
		end
		
		def save_urls urls
			append("public/webparser/sitemap/#{@host}/#{DateTime.now.strftime('%Y_%m_%d')}.json", urls.to_json) if urls.present?
		end
	end

end
