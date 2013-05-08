# coding: utf-8
class BrokerPump < Pool

  def worker
    forever do
      $redis.subscribe(:firehose) do |on|
        on.message do |channel, message|
          downstream.publish(channel, message)
          return if must_stop?
        end
      end
    end
  end

  def downstream
    # todo: use config
    @downstream ||= Redis.new(:db => 2)
  end

end