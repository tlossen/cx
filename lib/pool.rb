# coding: utf-8
require "sys/proctable"

class Pool

  def run
    init
    forever do
      if shutdown_requested
        stop_all_workers
        sleep(0.1) while child_count > 0
        return
      elsif child_count < pool_size
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
  def worker_body
    i = 0
    forever do
      return if stop_requested
      puts "#{Process.pid}: #{i += 1}"
      sleep(1)
    end
  end

  def forever(&block)
    loop do
      begin
        yield
      rescue Exception => e
        log_error(e)
        sleep(0.1)
      end
    end
  end

  def log_error(e)
    $redis.lpush(key("errors"), [Time.stamp, e.message].join(" "))
    $redis.ltrim(key("errors"), 20)
  rescue Exception => ignored
  end

  def stop_requested
    not $redis.sismember(key("workers"), Process.pid)
  end

private

  def init
    $redis.set(key("master"), Process.pid)
    $redis.setnx(key("size"), 1)
    $redis.del(key("workers"))
  end

  def shutdown_requested
    not $redis.exists(key("master"))
  end

  def start_worker
    pid = fork { worker }
    Process.detach(pid)
  end

  def worker
    $redis = Redis.new
    $redis.sadd(key("workers"), Process.pid)
    worker_body
  end

  def stop_worker
    $redis.spop(key("workers"))
  end

  def stop_all_workers
    $redis.del(key("workers"))
  end

  def worker_count
    $redis.scard(key("workers"))
  end

  def child_count
    Sys::ProcTable.ps.count { |p| p.ppid == Process.pid }
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

end