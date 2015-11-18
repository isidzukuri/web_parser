module WebParser
	class SimpleQueue
		include ThreadLock
		attr_reader :store, :total
		
		def initialize items, lock = nil
			@lock = lock if lock
		    @store = items
		    @total = items.count
		    @items_count = items.count
		    @items_shifted = 0
		    super()
		end

		def next_item
			thread_lock.synchronize do
				@items_count -= 1
				@items_shifted += 1
				@store.shift
			end
		end

		def items_left
			@items_count
		end

		def shifted
			@items_shifted
		end

	end
end