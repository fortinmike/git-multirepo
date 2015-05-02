module MultiRepo
  class TrackingFile
    def self.update_internal(file, new_content)
      old_content = File.exists?(file) ? File.read(file) : nil
      File.write(file, new_content)
      return new_content != old_content
    end
  end
end