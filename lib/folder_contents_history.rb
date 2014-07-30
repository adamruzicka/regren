class FolderContentsHistory
  require 'multi_json'

  def initialize(entries = {})
    @entries = entries
  end

  def load_entries(path = '.')
    entries = Dir["#{path}/*"].reduce({}) do |hash, item|
      pathless = item.gsub(/#{path}\//, '')
      hash.update(pathless => FileNameHistory.new(pathless))
    end
    @entries.merge!(entries) do |_key, old_hash, new_hash|
      old_hash.history.length > new_hash.history.length ? old_hash : new_hash
    end
  end

  def plan_renames(regexp, replacement)
    @entries.select { |key, _value| key[regexp] }.each_pair do |_key, value|
      value.plan_rename(regexp, replacement)
    end
  end

  def plan_rollbacks
    @entries.each_value do |file_history|
      file_history.plan_rollback
    end
  end

  def plan_reapplication(path)
    entries = Dir["#{path}/*"].map { |file| file.gsub(/#{path}\//, '') }
    histories = @entries.values
    @entries = merge_histories(histories, entries)
    @entries.select! { |_name, history| history }
    @entries.each { |name, history| history.plan_reapplication(name) }
  end

  def merge_histories(old, new)
    new.reduce({}) do |hash, item|
      hash.tap do |obj|
        new_history = old.select { |history| history.was_named? item }.first
        obj.update(item => new_history.clone) unless new_history.nil?
      end
    end
  end

  def execute
    changed.each_pair do |key, value|
      value.rename
      @entries[value.current] = @entries.delete(key)
    end
  end

  def log(regexp = '', replacement = '')
    if conflicts?
      puts <<-NOTE.gsub(/^.*\|/, '').colorize(:color => :red)
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
    with_history = @entries
      .select { |_name, history| history.history.length > 1 }
    backup = with_history.reduce({}) do |hash, item|
      hash.update(item.last.to_hash)
    end
    File.write(where, MultiJson.dump(backup, :pretty => true))
  end

  def to_hash(input_hash = @entries)
    input_hash.reduce({}) do |hash, entry|
      hash.update(entry[0] => entry[1].to_hash)
    end
  end

  def changed
    @entries.select { |_key, value| value.changed? && value.present? }
  end

  def show_history(files)
    files.each do |file|
      @entries[file] = FileNameHistory.new(file) unless @entries[file]
      @entries[file].print_history
    end
  end

  def conflicts?
    # changed.map { |entry| entry.last }.compact.uniq.length < changed.length
    @entries.map do |entry|
      entry.last.last_name
    end.compact.uniq.length < @entries.length
  end

  def self.new_from_history(history_file)
    entries = MultiJson.load(File.read(history_file)).reduce({}) do |hash, item|
      hash.update(item.first => FileNameHistory.new_from_history(item.last))
    end
    FolderContentsHistory.new(entries)
  end
end
