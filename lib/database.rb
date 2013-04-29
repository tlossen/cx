# coding: utf-8
class Database

  def initialize(params)
    @db = Mysql2::Client.new(params)
  end

  def create_table(name, columns)
    table_def = columns.to_a.map { |c| c.join(" ") }.join(",")
    exec "drop table if exists #{name}"
    exec "create table #{name} (#{table_def})"
  end

  def insert(table, columns)
    keys, values = columns.keys.join(","), columns.values.join(",")
    exec "insert into #{table} (#{keys}) values (#{values})"
    @db.last_id
  end

  def update(table, statement)
    exec "update #{table} #{statement}"
    @db.affected_rows
  end

  def transaction(&block)
    must_rollback = false
    exec "start transaction"
    begin
      yield
    rescue
      must_rollback = true
      raise
    ensure
      exec(must_rollback ? "rollback" : "commit")
    end
  end

  def exec(statement)
    # puts statement
    @db.query(statement)
  end

end