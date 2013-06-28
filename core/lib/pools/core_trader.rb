# coding: utf-8
class CoreTrader < Pool

  TRADE_CREATE = TradeCreate.new

  def worker
    forever do
      return if stop_requested?
      trade_id = TRADE_CREATE.execute
      $redis.lpush("trades", trade_id) if trade_id
    end
  end

end