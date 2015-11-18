module WebParser
	class Proxy < Initializator
		include ThreadLock

		def get_list_from_url
			proxy_list = HideMyAss.new({:agent => @agent}).get_list_from_url
			proxy_list
		end

		def get_queue
			SimpleQueue.new(get_list_from_url())
		end

		def get_list_from_file
			HideMyAss.new().get_list_from_file
		end
		
	end

end
