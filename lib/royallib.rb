class Royallib < WebParser::Parser

	# Royallib.new(:threads_number => 5, :sitemap_from_file => true).parse_now
	
	def parse_now
		parse 'http://royallib.com/books/en/0/0/', {:href =>/book\//}, {:href =>/books\/en\/\d/}
	end			
		
	def extract_data page
		data = {}
		td = page.search('.content table table td')
		td.each do |one|
			bold = one.search('b')[0]
			bold = bold.text if !bold.nil?
			case bold
				when "Автор:"
					data[:author_full] =  one.search('a')[0].text
					name_parts = data[:author_full].split(' ')
					data[:author_last] = name_parts[0]
					data[:author_first] = name_parts[1] if name_parts[1].present?
				when "Жанр:"
					data[:genres_list] = one.search('a')[0].text
				when "Название:"
					one.css('b').remove
					data[:title] = one.text.strip
				when "Аннотация:"
					one.css('b').remove
					data[:description] = one.text.strip
			end
		end
		data
	end

	def extract_text data, page, agent
		result = false
		file_href = page.link_with(:text => 'Скачать в формате TXT')
		if file_href
			url = file_href.uri.to_s
			txt_zip = get_file url, agent, true
			files = files_from_io_zip(txt_zip, /.txt$/)
			# files = files_from_zip(extract_zip_file("public/webparser/downloads/royallib.com/A_Legyzhetetlen.zip"), 'txt')
			files = files_from_io_zip(txt_zip, /\.[[:alpha:]]{3}$/, false) if !files.present?
			if files.present?
				if files.count > 1
					message = "more then 1 txt file".yellow 
					@log[page.uri.to_s] << message
				end
				text = files[0][:body]
				parts = text.split("\r\n\r\n\r\n\r\n")
				parts.pop
				parts.shift
				data.text = @html_entities.decode parts.join("\r\n\r\n\r\n\r\n")
				data.save_text
				result = true 
			else
				@log[page.uri.to_s] << "no text, no txt files".red
			end
		else
			@log[page.uri.to_s] << "no text, no txt href".red
		end
		result
	end

	def extract_img data, page, agent
		img_tag = page.search('.content img')
		img_url = img_tag[0].attribute('src').to_s
		data.save_img(img_url) if img_url.split('/').last != "cover.jpg"
	end

	def encode str
		begin
			str.force_encoding('Windows-1251').encode('UTF-8')
		rescue Encoding::UndefinedConversionError
			false
		end
	end

end

