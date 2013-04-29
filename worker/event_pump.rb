# coding: utf-8
class EventPump

  def self.run
    upstream.subscribe(:firehose) do |on|
      on.message do |channel, message|
        puts "#{channel}: #{message}"
        downstream.publish("_#{channel}", message)
        # upstream.unsubscribe if message == "exit"
      end
    end
  end

  def self.upstream
    @upstream ||= Redis.new
  end

  def self.downstream
    @downstream ||= Redis.new
  end

end