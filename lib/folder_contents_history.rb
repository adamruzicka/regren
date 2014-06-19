class FolderContentsHistory

  require 'json'

  def initialize(entries = {})
    @entries = entries
  end

  def load_entries(path)
    @entries = Dir["#{path}/*"].inject({}) do |hash, item|
      pathless = item.gsub(/#{path}\//,'')
      hash.update(pathless => FileNameHistory.new(pathless))
    end
  end

  def plan_renames(regexp, replacement)
    @entries.select { |key, value| key[regexp] }.each_pair do |key, value|
      value.plan_rename(regexp, replacement)
    end
  end

  def plan_rollbacks
    @entries.each_value do |file_history|
      file_history.plan_rollback
    end
  end

  def plan_reapplication(path)
    entries = Dir["#{path}/*"].map { |file| file.gsub(/#{path}\//,'') }
    histories = @entries.values
    @entries = entries.inject({}) do |hash, item|
      hash.tap do |obj|
        new_history = histories.select { |history| history.was_named? item }.first
        obj.update(item => new_history.clone) unless new_history.nil?
      end
    end
    @entries.select! { |name, history| history }
    @entries.each { |name, history| history.plan_reapplication(name) }
  end

  def execute
    changed.each_pair do |key, value|
      value.rename
      @entries[value.current] = @entries.delete(key)
    end
  end

  def log
    if conflicts?
      puts <<-NOTE.gsub(/^.*\|/, '')
      |==================================================
      |!!! Some files would be lost by this operation !!!
      |==================================================
      NOTE
    end
    changed.each_value do |file_history|
      file_history.log
    end
  end

  def log_backup(where)
    with_history = @entries.select { |name, history| history.history.length > 1 }
    backup = with_history.inject({}) do |hash, item|
      hash.update(item.last.to_hash)
    end
    File.write(where, JSON.pretty_generate(backup))
  end

  def to_hash(input_hash = @entries)
    input_hash.inject({}) do |hash, entry|
      hash.update(entry[0] => entry[1].to_hash)
    end
  end

  def changed
    @entries.select { |_key, value| value.changed? }
  end

  def show_history(files)
    files.each do |file|
      @entries[file] = FileNameHistory.new(file) unless @entries[file]
      @entries[file].print_history
    end
  end

  def conflicts?
    #changed.map { |entry| entry.last }.compact.uniq.length < changed.length
    @entries.map { |entry| entry.last.last_name }.compact.uniq.length < @entries.length
  end

  def self.new_from_history(history_file)
    entries = JSON.parse(File.read(history_file)).inject({}) do |hash, item|
      hash.update(item.first => FileNameHistory.new_from_history(item.last))
    end
    FolderContentsHistory.new(entries)
  end
end
