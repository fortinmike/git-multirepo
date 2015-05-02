module MultiRepo
  class TrackingFile
    def self.update_internal(file, new_content)
      old_content = File.read(file)
      File.write(file, new_content)
      return new_content != old_content
    end
  end
end