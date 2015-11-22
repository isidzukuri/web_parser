class ParsedItem < ActiveRecord::Base
	include WebParser::WorkWithFiles

  
  def fill_language_all
  	totals = {:no_file => 0}
  	update_items = {}
  	wl = WhatLanguage.new(:all)
		ParsedItem.select(:language, :id, :host).all.each_with_index do |item, i|
			puts (i+1).to_s.green
			text = read_file("public/webparser/txt/#{item.host}/#{item.id}.txt")
			if !text.present?
				totals[:no_file] += 1
				next
			end
			lang = wl.language(text)
			update_items[item.id] = {:language => lang.to_s}
			totals[lang].present? ? totals[lang] += 1 : totals[lang] = 1
		end
    ParsedItem.update(update_items.keys, update_items.values)
		ap totals
  end


end