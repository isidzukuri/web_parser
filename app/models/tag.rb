class Tag < ActiveRecord::Base
	include LibraryLib
	self.table_name = 'tags'

end