class StoredFile
  def initialize(file)
    @file = file
  end

  def to_path
    @file
  end

  def exist?
    File.exist?(self)
  end

  def remove!
    File.delete(self)
  end

  def with_chunks
    File.open(@file, 'rb') do |f|
      while data = f.read(500000)
        yield data
      end
    end
  end
end
