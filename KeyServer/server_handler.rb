require 'bundler/setup'
require 'securerandom'
require 'sqlite3'
require './expiry_module'

class KeyServerAPI
  include CheckExpiry
  attr_reader :unblock_time, :delete_time, :db #db attribute reader should be removed in production

  def initialize(unblock_time,delete_time)
    @unblock_time = unblock_time
    @delete_time = delete_time
    @db = SQLite3::Database.new "keys.db"
    initialize_db(@db);
    @db = SQLite3::Database.open "keys.db"
    @mutex = Mutex.new

    thread = Thread.new do
      while true
        sleep 1
        blocked_keys = db.execute("select * from blocked_keys where "+Time.now.to_i.to_s+" - blocked_at > 0")
        blocked_keys.each do |key|
          unblock_key(key[0])
        end
      end
    end

  end

  def initialize_db(db)
    begin
      # Created 2 tables for the fact that blocked_keys will be much lesser than
      # unblocked keys and it will not make sense to go through all keys everytime so divided computation
      db.execute "CREATE TABLE IF NOT EXISTS unblocked_keys(key_value TEXT PRIMARY KEY, alive INTEGER)"
      db.execute "CREATE TABLE IF NOT EXISTS blocked_keys(key_value TEXT PRIMARY KEY, alive INTEGER, blocked_at INTEGER)"
      db.execute "delete from unblocked_keys where "+Time.now.to_i.to_s+" - alive > 0"
      db.execute "delete from blocked_keys where "+Time.now.to_i.to_s+" - alive > 0"
    ensure
      db.close if db
    end
  end

  def create_key
    begin
      new_key = SecureRandom.uuid
      time = Time.now
      stm = @db.prepare "INSERT INTO unblocked_keys VALUES(?,?)"
      stm.bind_param 1, new_key
      stm.bind_param 2, (Time.now.to_i + delete_time).to_s
      rs = stm.execute
      new_key
    rescue StandardError => e
      puts "Error : "+e.message
      retry
    end
  end

  def block_key(key)
    @mutex.synchronize do
      entry = db.get_first_row( "select * from unblocked_keys where key_value = :key_value",
                                {"key_value" => key.to_s})
      if(entry)
        return false if CheckExpiry.is_unblocked_expired?(entry,db)
        db.execute("Delete from unblocked_keys where key_value = :key_value",
                   {"key_value" => key.to_s})
        db.execute("INSERT INTO blocked_keys VALUES(:key_value,:alive,:block)",
                   {"key_value" => key.to_s,"alive" => entry[1],"block" => (Time.now.to_i + @unblock_time).to_s})
        return true
      else
        false
      end
    end
  end

  def unblock_key(key)
    @mutex.synchronize do
      entry = db.get_first_row( "select * from blocked_keys where key_value = :key_value",
                                {"key_value" => key.to_s})
      if(entry)
        return false if CheckExpiry.is_blocked_expired?(entry,db)
        db.execute("Delete from blocked_keys where key_value = :key_value",
                   {"key_value" => key.to_s})
        db.execute("INSERT INTO unblocked_keys VALUES(:key_value,:alive)",
                   {"key_value" => key.to_s,"alive" => entry[1]})
        return true
      else
        return false
      end
    end
    true
  end

  def delete_key(key)
    @mutex.synchronize do
      if is_available?(key,'blocked_keys')
        db.execute("Delete from blocked_keys where key_value = :key_value",
                   {"key_value" => key.to_s})
      elsif is_available?(key,'unblocked_keys')
        db.execute("Delete from unblocked_keys where key_value = :key_value",
                   {"key_value" => key.to_s})
      else
        return false
      end
      true
    end
  end

  def keep_alive(key)
    @mutex.synchronize do
      entry = db.get_first_row( "select * from blocked_keys where key_value = :key_value",
                                {"key_value" => key.to_s})
      if(entry)
        return false if CheckExpiry.is_blocked_expired?(entry,db)

        db.execute("update blocked_keys set alive = :alive where key_value = :key_value",
                   {"alive" => Time.now.to_i+@delete_time,"key_value" => key.to_s})
      elsif entry = db.get_first_row( "select * from unblocked_keys where key_value = :key_value",
                                      {"key_value" => key.to_s})
        if(entry)
          return false if CheckExpiry.is_unblocked_expired?(entry,db)
        end
        db.execute("update unblocked_keys set alive = :alive where key_value = :key_value",
                   {"alive" => Time.now.to_i+@delete_time,"key_value" => key.to_s})
      else
        return false
      end
    end
    true
  end

  def get_key
    begin
      entry = db.get_first_row("select * from unblocked_keys where 1")
      if entry!=nil
        hot_key = entry[0];
        if !block_key(hot_key)
          raise ArgumentError, " Key is Expired!"
        end
        return hot_key
      else
        return "403"
      end
    rescue ArgumentError
      retry
    end
  end

  def print_keys(keys)
    puts "\n\n######  \n"
    stm = @db.prepare "SELECT * FROM "+keys
    rs = stm.execute
    rs.each do |row|
      puts row.join "\s"
    end
    print "\n\n######\n"
  end

  def is_available?(key,table)
    return @db.get_first_value("select count(*) from "+table+" where key_value = :k",{"k" => key}) == 1
  end

  # Test helper method to simulate auto unblock by increasing key's age
  def simulate_auto_unblock(key,sec)
    db.query("update blocked_keys set blocked_at = blocked_at-#{sec} where key_value = '#{key}'")
  end

  # Test helper method to simulate auto delete by increasing key's age
  def simulate_auto_delete(key,sec)
    db.query("update blocked_keys set alive = alive-#{sec} where key_value = '#{key}'");
    db.query("update unblocked_keys set alive = alive-#{sec} where key_value = '#{key}'")
  end

  # Test helper to purge all keys
  def purge_all
    db.execute "delete from unblocked_keys where 1"
    db.execute "delete from blocked_keys where 1"
  end

end
