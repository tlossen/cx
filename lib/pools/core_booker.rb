# coding: utf-8
class CoreBooker < Pool

  def worker_body
    forever do
      return if stop_requested?
      trade_id = $redis.rpop("trades")
      if trade_id
        TradeBook.new(trade_id: trade_id).execute
      else
        sleep(0.1)
      end
    end
  end

end