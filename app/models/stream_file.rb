require 'securerandom'

class StreamFile
  def initialize(stream)
    @stream = stream
    @f_name = SecureRandom.uuid.gsub("-", "")
  end

  def filename
    @f_name
  end

  def content_type
    "application/octet-stream"
  end

  def store!
    new_path = File.join(self.class.storage_path, @f_name)
    File.open(new_path, 'wb') do |f|
      while data = @stream.read(2000000)
        f.write(data)
      end
    end
  end

  def self.sanitize_file_id(file_id)
    file_id.gsub(/[^0-9a-z]/i, '')
  end

  def self.find(file_id)
    handle = sanitize_file_id(file_id)
    return nil if handle.blank?
    file_name = File.join(storage_path, handle)
    sf = StoredFile.new(file_name)
    sf.exist? ? sf : nil
  end

  def self.storage_path
    File.join(HbxSoa::App.root, "..", "public", "filestore")
  end
end
