require 'dbm'

# Database utilities
module Database
  def self.execute_action(name)
    db = DBM.open("db/#{name}", 0666, DBM::WRCREAT)
    yield(db)
  ensure
    db.close unless db.closed?
  end

  def self.store(name, hash)
    execute_action(name) { |db| hash.each_key { |key| db[key] = hash[key] } }
  end

  def self.get_value(name, key)
    execute_action(name) { |db| db[key] }
  end

  def self.delete(name, key)
    execute_action(name) { |db| db.delete(key) }
  end

  def self.key?(name, key)
    execute_action(name) { |db| db.key?(key) }
  end
end
