module GoogleTranslator

	def translate from_lang, to_lang, text
		if @translator.nil?
			require 'google_translate'
			require 'google_translate/result_parser'
			@translator = GoogleTranslate.new
		end
		result = @translator.translate(from_lang, to_lang, text)
		result_parser = ResultParser.new result
		[result_parser.translation, result_parser.translit]
	end

end