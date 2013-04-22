# coding: utf-8
class Database

  def initialize(params)
    @db = Mysql2::Client.new(params)
  end

  def create_table(name, columns)
    table_def = columns.to_a.map { |c| c.join(" ") }.join(",")
    @db.query "drop table if exists #{name}"
    @db.query "create table #{name} (#{table_def})"
  end

  def insert(table, columns)
    keys, values = columns.keys.join(","), columns.values.join(",")
    @db.query "insert into #{table} (#{keys}) values (#{values})"
    @db.last_id
  end

  def update(table, statement)
    @db.query "update #{table} #{statement}"
    @db.affected_rows
  end

  def transaction(&block)
    must_rollback = false
    @db.query "start transaction"
    begin
      yield
    rescue
      must_rollback = true
      raise
    ensure
      @db.query(must_rollback ? "rollback" : "commit")
    end
  end

end