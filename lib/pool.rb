# coding: utf-8
require "sys/proctable"

class Pool

  def start
    init
    forever do
      if shutdown_requested?
        stop_all_workers
        sleep(0.1) while child_count > 0
        return
      elsif child_count < pool_size
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
  def worker_body
    pid, i = Process.pid, 0
    forever do
      return if stop_requested?
      item = $redis.rpop("test")
      if item
        raise "boom" if item == "boom"
        return if item == "exit"
        puts "[#{pid}] processing: #{item}"
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
        puts e.message
        log_error(e)
        pause
      end
    end
  end

  def log_error(e)
    $redis.lpush(key("errors"), [Time.stamp, e.message].join(" "))
    $redis.ltrim(key("errors"), 20)
  rescue Exception => ignored
  end

  def stop_requested?
    not $redis.sismember(key("workers"), Process.pid)
  end

private

  def init
    $redis.set(key("master"), Process.pid)
    $redis.setnx(key("size"), 1)
    $redis.del(key("workers"))
  end

  def shutdown_requested?
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
    $redis.srem(key("workers"), Process.pid)
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

  def track_current_workers
    $redis.multi do
      $redis.del(key("workers"))
      children.each do |worker|
        $redis.sadd(key("workers"), worker)
      end
    end
  end

  def child_count
    children.count
  end

  def children
    Sys::ProcTable.ps.select { |p| p.ppid == Process.pid }.map(&:pid)
  end

  def pause
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

end