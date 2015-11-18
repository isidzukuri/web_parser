class HideMyAss < WebParser::Initializator
	include WebParser::PageParser, WebParser::WorkWithFiles
	
	def get_list_from_url
		proxy_list = []
		@agent = Mechanize.new if @agent.nil?
		page = get_page('http://proxylist.hidemyass.com/', @agent)
		proxy_list = extract_data(page)
		save_proxy(proxy_list)
		proxy_list
	end

	def extract_data page
		proxy_list = []
		rows = page.first.search('#listable tr')
		rows.each do |row|
			item = {}
			row.search('td').each_with_index do |td, i|
				case i
				when 1
					good, bytes = [], []
					css = td.at_xpath('span/style/text()').to_s
					css.split.each {|l| good << $1 if l.match(/\.(.+?)\{.*inline/)}
					td.xpath('span/span | span | span/text()').each do |span|
				        if span.is_a?(Nokogiri::XML::Text)
				          bytes << $1 if span.content.strip.match(/\.{0,1}(.+)\.{0,1}/)
				        elsif (
				          (span['style'] && span['style'] =~ /inline/) ||
				          (span['class'] && good.include?(span['class'])) ||
				          (span['class'] =~ /^[0-9]/)
				          )
				          bytes << span.content
				        end
				    end
				    item[:ip] = bytes.join('.').gsub(/\.+/,'.')
				when 2 then item[:port] = td.content.strip
				end
			end
			proxy_list << item if !item.empty?
		end
		proxy_list
	end

	def save_proxy proxy_list
		append("public/webparser/proxy/#{self.class}_#{DateTime.now.strftime('%Y_%m_%d')}.json", proxy_list.to_json) if proxy_list.present?
	end

end