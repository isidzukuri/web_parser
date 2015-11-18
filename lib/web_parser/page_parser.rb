module WebParser
	module PageParser

		# exception
		# retry

		def get_page url, agent = false, use_cache = false
			agent = @agent if !agent
			if !use_cache
				message = "Crawling page #{url}".green
				defined?(@log) ? (@log[url] << message) : (puts message)
				begin
					page = agent.get(url)
				rescue NoMethodError
					raise NoMethodError.new("Parameter 'agent' should be Mechanize object")
				# rescue 
					# # if network error or not expected page
					# # change proxy 
					# agent = change_proxy(agent,url)
					# # and try again
					# page = agent.get(url)
					# # if not succeed raise exception
				end
			else
				if !page = CACHE.read(url)
					page = agent.get(url)
					CACHE.write(url, page.body)
				else
					page = Mechanize::Page.new(URI(url),{'content-type'=>'text/html'},page,nil,agent)
				end
			end
			[page, agent]
		end

		def change_proxy agent, url = false
			@proxy_list = Proxy.new({:agent => agent}).get_queue if @proxy_list.nil?
			if !proxy = @proxy_list.next_item
				message = "refreshing proxy list".yellow
				defined?(@log) ? (@log[url] << message) : (puts message)
				@proxy_list = Proxy.new({:agent => agent}).get_queue 
				proxy = @proxy_list.next_item
			end
			raise Exception.new("No available proxy") if !proxy
			agent.set_proxy(proxy[:ip], proxy[:port])
		end
		
		def get_file url, agent = false, save_file = false
			host = @host ? @host : 'default'
			agent = @agent if !agent
			agent.pluggable_parser.default = Mechanize::Download
			file = agent.get(url)
			file_body = file.body.force_encoding('UTF-8')
			append("public/webparser/downloads/#{@host}/#{file.filename}", file_body) if save_file
			# if save_file
			# 	dir = "public/webparser/downloads/#{@host}/"
			# 	create_dir dir
			# 	file.save("#{dir}#{file.filename}")
			# end
			file_body
		end

	end

end