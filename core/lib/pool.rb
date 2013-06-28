# coding: utf-8
require "sys/proctable"

class Pool

  def start
    init
    forever do
      if shutdown_requested?
        stop_all!
        return
      elsif children.count < pool_size
        track_current_workers
        start_worker
      elsif worker_count > pool_size
        stop_worker
      else
        sleep(0.1)
      end
    end
  end

protected

  # override this!
  def worker
    i = 0
    forever do
      return if must_stop?
      item = $redis.rpop("todo")
      if item
        return if item == "exit"
        raise "boom" if item == "boom"
        puts "[#{pid}] #{item}"
      else
        puts "[#{pid}] #{i += 1}"
        sleep(1)
      end
    end
  end

  def forever(&block)
    loop do
      begin
        yield
      rescue Exception => e
        puts "[#{pid}] #{e.message}"
        log_error(e)
        pause_all!
      end
    end
  end

  def must_stop?
    master_gone? || stop_requested?
  end

  def log_error(e)
    $redis.lpush(key("errors"), [Time.stamp, e.message].join(" "))
    $redis.ltrim(key("errors"), 20)
  rescue Exception => ignored
  end

private

  def init
    $redis.set(key("master"), pid)
    $redis.setnx(key("size"), 1)
    $redis.del(key("workers"))
  end

  def shutdown_requested?
    not $redis.exists(key("master"))
  end

  def stop_requested?
    not $redis.sismember(key("workers"), pid)
  end

  def start_worker
    pid = fork { setup_worker }
    Process.detach(pid)
  end

  def setup_worker
    $redis = Redis.new
    $redis.sadd(key("workers"), pid)
    worker
  ensure
    $redis.srem(key("workers"), pid)
  end

  def stop_worker
    $redis.spop(key("workers"))
  end

  def stop_all!
    $redis.del(key("workers"))
    sleep(0.1) while children.count > 0
  end

  def worker_count
    $redis.scard(key("workers"))
  end

  def track_current_workers
    $redis.multi do
      $redis.del(key("workers"))
      children.each do |worker|
        $redis.sadd(key("workers"), worker)
      end
    end
  end

  def children
    Sys::ProcTable.ps.select { |p| p.ppid == pid }.map(&:pid)
  end

  def master_gone?
    Sys::ProcTable.ps(master.to_i).nil?
  end

  def master
    $redis.get(key("master"))
  end

  def pause_all!
    $redis.set(key("size"), 0)
  end

  def pool_size
    $redis.get(key("size")).to_i
  end

  def key(name)
    "#{pool_id}:#{name}"
  end

  def pool_id
    self.class.name.to_underscore
  end

  def pid
    Process.pid
  end

end