class Genre < LibraryDb
	self.table_name = 'genre'

	def add_seo_name params
		params[:seo_name] = create_seo_name(params[:name], 'seo_name')
		params
	end

end