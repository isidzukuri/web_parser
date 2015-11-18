module WebParser
	class Parser < Initializator
		include PageParser, ThreadLock, WorkWithFiles

		attr_reader :log
		
		def initialize init_vars = {}
			@log = {}
			@html_entities = HTMLEntities.new
			ActiveRecord::Base.logger = nil
		    super
		end

		def parse url, item_attr, paginator_attr = nil
			sitemap = Sitemap.new(:threads_number => @threads_number)
			@url_queue = sitemap.get_urls_queue(url, item_attr, paginator_attr, @sitemap_from_file)
			@host = sitemap.host
			# RubyProf.measure_mode = RubyProf::WALL_TIME
			# RubyProf.start
			threads = []
			@threads_number.times do 
				threads << Thread.new do
					agent = Mechanize.new
					next_url = @url_queue.next_item
					while next_url do
						@log[next_url] = []
						@log[next_url] << "#{@url_queue.shifted}/#{@url_queue.total}".green
						begin
					   		parse_one(next_url, agent)
					   		puts "[#{@log[next_url][0]}] #{next_url}"
					   	rescue WebParserException => e
					   		@log[next_url] << e.message.to_s.red
					   		puts "[#{@log[next_url][0].red}] #{next_url}"
					   		@log[next_url].each_with_index{|message,i| puts "\t- #{message}" if i > 0 }
					   	end
					   	
					   	# raise Exception #if @url_queue.shifted == 100
					   	next_url = @url_queue.next_item
					end
				end
			end
			threads.each { |thr| thr.join }
			# profiler = RubyProf.stop
			# printer = RubyProf::GraphPrinter.new(profiler)
			# printer.print(STDOUT, {})
			puts "[end]".green
		end

		# get page data
		# get text file
		# get img
		# save data
		def parse_one url, agent
			# url = 'http://royallib.com/book/Lem_Stanislaw/A_Legyzhetetlen.html'
			page, agent = get_page(url, agent, @use_cache)
			data = WebParser::Data.new(@host, agent)
			data.store = data.store.merge(extract_data(page))
			data.store[:url] = url
			data.save
			if extract_text(data, page, agent) 
				extract_img(data, page, agent)
			else
				abort_save(data, url)
			end
		end

		def extract_data page
			raise NoMethodError.new("Implement this method in ur lib") 
		end

		def extract_text data, page, agent
			raise NoMethodError.new("Implement this method in ur lib") 
		end

		def extract_img data, page, agent
			raise NoMethodError.new("Implement this method in ur lib") 
		end

		def abort_save data, url = false
			@log[url] << "deleting item from db".green
			data.item.delete
			raise WebParserException.new("Something went wrong with page #{url}")
		end
	end
end
