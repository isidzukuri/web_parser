module WebParser
	class Data 
		include WorkWithFiles
		attr_accessor :store, :text, :item

		def initialize host = 'unknown_host', agent = nil
			@host = host
			@agent = agent
			@store = {
				:title => '', 
				:author_full => '', 
				:author_first => '', 
				:author_last => '', 
				:description => '', 
				:img_format => '', 
				:genres_list => '', 
				:tags_list => '', 
				:language => '', 
				:host => '',
				:url => ''
			}
			@id = nil
			@text = ""
		end

		def save
			@store[:host] = @host
			# ap @store
			@item = ParsedItem.create(@store)
			@id = @item.id
		end

		def save_img img_url
			img = @agent.get(img_url)
			extension =  img_url.split('.').last
			if img.present?
				img.save("public/webparser/img/#{@host}/#{@id}.#{extension}") 
				@item.img_format = extension
				@item.save
			end
		end

		def save_text
			append("public/webparser/txt/#{@host}/#{@id}.txt", @text) 
		end

	end

end
