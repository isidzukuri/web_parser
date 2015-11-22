class Author < LibraryDb
	self.table_name = 'authors'

	def add_seo_name params
		params[:seo] = create_seo_name(params[:full_name])
		params[:bio] = ''
		params
	end

end