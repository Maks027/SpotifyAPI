require 'dbm'

module Database
  def Database.execute_action(name)
    begin
      db = DBM.open("db/#{name}", 0666, DBM::WRCREAT)
      yield(db)
    ensure
      db.close unless db.closed?
    end
  end

  def Database.store(name, hash)
    execute_action(name) { |db|  hash.keys.each { |key| db[key] = hash[key] } }
  end

  def Database.get_value(name, key)
    execute_action(name) { |db| db[key] }
  end

  def Database.delete(name, key)
    execute_action(name) { |db| db.delete(key) }
  end

  def Database.has_key?(name, key)
    execute_action(name) { |db| db.has_key?(key) }
  end
end