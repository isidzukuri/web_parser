class Tag < LibraryDb
	self.table_name = 'tags'

	# has_and_belongs_to_many :books, class_name: "Book"

	def add_seo_name params
		params[:seo_url] = create_seo_name(params[:title], 'seo_url')
		params
	end
end