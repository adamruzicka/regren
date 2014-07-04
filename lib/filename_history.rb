class FileNameHistory
  attr_reader :history, :current

  def initialize(name, history = [])
    @history = history.empty? ? [name] : history
    @current = name
  end

  def to_hash
    {
      @history.last => @history
    }
  end

  def self.new_from_history(history)
    FileNameHistory.new(history.last,
                        history)
  end

  def present?
    File.exist?(@current)
  end

  def original
    @history.first
  end

  def last_name
    @history.last
  end

  def plan_rename(regexp, replacement)
    new_name = @current.gsub(regexp, replacement)
    @history << new_name if new_name != current
  end

  def plan_rollback
    @history << original
  end

  def was_named?(name)
    @history.include? name
  end

  def plan_reapplication(name)
    @current = name
  end

  def changed?
    @history.last != @current
  end

  def rename
    File.rename("#{@current}", "#{@history.last}")
    @current = @history.last
  end

  def print_history(where = $stdout)
    where.puts(@current)
    where.print "-> #{@history.join("\n-> ")}\n\n"
  end

  def log(where = $stdout)
    return unless changed?
    where.puts(@current)
    where.puts("-> #{@history.last}")
  end
end
