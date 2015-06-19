module CheckExpiry

  def is_unblocked_expired?(entry,db)
    if(Time.now.to_i - entry[1].to_i) > 0
      db.execute("Delete from unblocked_keys where key_value = :key_value",
                 {"key_value" => entry[0].to_s})
      return true
    end
    false
  end

  def is_blocked_expired?(entry,db)
    if(Time.now.to_i - entry[1].to_i) > 0
      db.execute("Delete from blocked_keys where key_value = :key_value",
                 {"key_value" => entry[0].to_s})
      return true
    end
    false
  end

  module_function :is_blocked_expired?, :is_unblocked_expired?

end
