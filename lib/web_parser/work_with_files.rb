module WebParser
	module WorkWithFiles

		def append(path, data)
			path = File.expand_path path
			create_dir File.dirname(path)
			# File.open(path, "w+"){|f| f.write data }
			begin
				file=File.new(path, "w+")
				file.puts(data)
				size = file.size
				file.close
				size
			rescue Errno::EMFILE => e
				ObjectSpace.each_object(File) do |f|
				  puts "%s: %d" % [f.path, f.fileno] unless f.closed?
				end
				raise Errno::EMFILE.new(e.message)
			end
		end

		def create_dir path
			FileUtils.mkdir_p path
		end

		def copy_file(src, dst)
		  create_dir(File.dirname(dst))
		  FileUtils.cp(src, dst)
		end

		def extract_zip file_body
			Zip::Archive.open_buffer(file_body)
		end

		def extract_zip_file path_to_file
			extract_zip(open(path_to_file).read)
		end

		def files_from_zip ziped, pattern = false, match = true
			files = []
			ziped.each do |file| 
				filename = encode(file.name)
				break if !filename	
				if pattern	
					if match
						next if filename.match(pattern).nil?
					else
						next if filename.match(pattern)
					end	
				end
				file_body = encode(file.read)
				break if !file_body
				files << {:filename => filename, :body => file_body}
			end
			files
		end

		def files_from_io_zip io_zip, extension = false, match = true
			files_from_zip(extract_zip(io_zip), extension, match)
		end

		def encode str
			str
		end

		def read_file path
				data = nil
				if File.exist?(path)
					file = File.open(path)
					data = file.read
					file.close
				end
				data
		end
		
	end

end
