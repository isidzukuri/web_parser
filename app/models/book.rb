class Book < LibraryDb
	self.table_name = 'book'

	# Book.new.copy_all_from_parsed(:language => 'polish', :host => 'royallib.com')
	def copy_all_from_parsed params
		ActiveRecord::Base.logger = nil
		@authors = {}
		@genres = {}
		@language = params[:language].present? ? params[:language] : 'default'
		# взяти ров з парсед айтемс
		# ParsedItem.where(:language => 'polish', :host => 'royallib.com').all
		parsed_items = ParsedItem.where(params).all
		total = parsed_items.count
		parsed_items.each_with_index do |item, i|
			id = copy_one_from_parsed(item)
			puts "[#{(i+1).to_s.green}/#{total.to_s.green}] #{id.to_s.blue}"
		end
		total
	end

	def copy_one_from_parsed item
		id = false
		# взяти імя автора провірити чи він існує
		# 	- вернути айдіху
		# 	- створити автора і вернути айдіху
		if !@authors[item.author_full].present?
			author_id = Author.new.create_if_not_exists(:full_name => item.author_full, :f_name => item.author_first, :l_name => item.author_last)
			@authors[item.author_full] = author_id
		else
			author_id = @authors[item.author_full]
		end

		if !@genres[item.genres_list].present?
			genre_id = Genre.new.create_if_not_exists(:name => item.genres_list)
			@genres[item.genres_list] = genre_id
		else
			genre_id = @genres[item.genres_list]
		end

		# провірити чи існує така книга по назві і айді автора
		if !id = check_exists_by(:authorid => author_id, :bookname => item.title)
			seo_name = create_seo_name("#{item.author_full}_#{item.title}")

			# порахувати розмір файлу
			file = read_file("public/webparser/txt/#{item.host}/#{item.id}.txt")
			if file
				# зберегти книгу
				book = save_book(
					:authorid => author_id,
					:bookname => item.title,
					:bookdescribe => item.description,
					:genre => genre_id,
					:seo => seo_name,
					:txtfile => seo_name,
					:txt_size_kb => txt_size_kb
				)
				# створити ров в book_support
				BookSupport.create({:id => book.id})

				# зкопіювати текст, картинку
				txt_name = "#{book.id}_#{seo_name}.txt"
				book.txt_size_kb = append("public/#{@language}/txt/#{txt_name}", file)/1024
				if item.img_format.present?
					img_src = "public/webparser/img/#{item.host}/#{item.id}.#{item.img_format}"
					img_name = "#{book.id}_#{seo_name}#{File.extname(File.basename(img_src))}"
					copy_file(img_src, "public/#{@language}/img/#{img_name}")
					book.txtfile = txt_name
					book.cover = img_name
				end
				book.save
				# додати теги якшо є
				id = book.id
			end
		end
		id
	end


	def save_book params
		self.class.create(params)
	end
end