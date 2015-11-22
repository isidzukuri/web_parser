class LibraryDb < ActiveRecord::Base
	self.abstract_class = true
	include WebParser::WorkWithFiles, GoogleTranslator

	establish_connection :javalibr_pl

	def transliterate str
		str.to_ascii
	end

	def create_seo_name str, column_key = 'seo'
		seo_name = transliterate(str).parameterize[0..95]
		if self.class.where({column_key => seo_name}).first
			seo_name = create_seo_name("#{seo_name}_1", column_key)
		end
		seo_name
	end

	def check_exists_by params
		item = self.class.where(params).first
		item.present? ? item.id : nil
	end

	def create_if_not_exists params
		if !id = check_exists_by(params)
			params = add_seo_name(params)
			created = self.class.create(params)
			id = created.id
		end
		id
	end

	def add_seo_name params
		params
	end

end