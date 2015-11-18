module WebParser
	module ThreadLock 

		def initialize *init_vars
			@threads_number = 1 if @threads_number.nil?
			super
		end
		
		def thread_lock
			@lock = !@lock.nil? ? @lock : Mutex.new
			@lock
		end

	end
end