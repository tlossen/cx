# coding: utf-8
class CoreEventPump < Pool

  def worker_body
    forever do
      $redis.subscribe(:firehose) do |on|
        on.message do |channel, message|
          downstream.publish(channel, message)
          return if stop_requested
        end
      end
    end
  end

  def downstream
    # todo: use config
    @downstream ||= Redis.new(:db => 2)
  end

end