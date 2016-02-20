class Manybooks < WebParser::Parser

	# TODO: extract text from pdf 
	# Manybooks.new(:threads_number => 5, :sitemap_from_file => true).parse_now
	
	def parse_now
		parse 'http://manybooks.net/language.php', {:href =>/titles\//}, {:href =>/language.php\?code/}, {:href =>/language.php\?code/}
	end			
		
	def extract_data page
		data = {}
		data[:title] = page.search('.booktitle').text.strip
		descr_tag = page.search('.notes p')
		data[:description] = descr_tag.text.strip if descr_tag.present?
# ap page.uri.path.split('/').last.split('.').pop.join('.')

		fields = page.search('.title-info')
		fields.each do |one|
			title = one.search('span')[0].text.split(':')[0].downcase
			case title
				when "author"
					data[:author_full] =  one.search('a')[0].text
					name_parts = data[:author_full].split(' ')
					data[:author_last] = name_parts.pop
					data[:author_first] = name_parts.join(' ')
				when "language"
					data[:language] =  one.search('a')[0].text.downcase
				when "genres"
					links = one.search('a')
					if links
						names = links.map{|l| l.text.downcase} 
						data[:genres_list] = names[0].capitalize
						data[:tags_list] = names.join('|')
					end
			end
		end
		# extract_text data, page, nil
		data
		# ap data
		# false
	end

	def extract_text data, page, agent

		# 1:pdf:.pdf:pdf
		# 1:text:.txt:text

		text_option = page.search('option[value="1:text:.txt:text"]')
		# text_option = page.search('option[value="1:pdf:.pdf:pdf"]') if !text_option.present?

			# ap text_option

		result = false
		# file_href = page.link_with(:text => 'Скачать в формате TXT')
		if text_option.present?


			id = page.uri.to_s.scan(/titles\/([^.]*).html/)[0][0]

			file_href = "http://manybooks.net/send/1:text:.txt:text/#{id}/#{id}.txt"
			# ap file_href

			# 

		# 	url = file_href.uri.to_s
		# agent = Mechanize.new
			file_body = get_file file_href, agent, true
			if file_body.present?
				# ap file_body
				
				file_body.sub!('A free ebook from http://manybooks.net/', "")
				file_body.sub!('from http://manybooks.net/', "")
				data.text = @html_entities.decode file_body
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
		img_tag = page.search('.cover-download-wrapper img')
		img_url = img_tag[0].attribute('src').to_s
		data.save_img(img_url) if img_url.split('/').last != "cover.jpg"
	end

	# def encode str
	# 	begin
	# 		str.encode('UTF-8')
	# 	rescue Encoding::UndefinedConversionError
	# 		false
	# 	end
	# end

end

