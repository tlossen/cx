# coding: utf-8
class TradeCreate < Action

  params :trade_id

  def execute
    $db.transaction do
      return unless trade
      book_bidder
      book_asker
      update_trade
    end
  end

private

  def book_bidder
    $db.update(:accounts,
      "set btc = btc + #{btc},
      eur = eur - #{eur_total}
      where account_id = #{bidder_id}"
    )
    $db.insert(:deltas,
      trade_id:   trade_id,
      account_id: bidder_id,
      eur:        -eur_total,
      btc:        +btc,
      booked_at:  stamp
    )
  end

  def book_asker
    $db.update(:accounts,
      "set btc = btc - #{btc},
      eur = eur + #{eur_total}
      where account_id = #{asker_id}"
    )
    $db.insert(:deltas,
      trade_id:   trade_id,
      account_id: asker_id,
      eur:        +eur_total,
      btc:        -btc,
      booked_at:  stamp
    )
  end

  def update_trade
    $db.update(:trades,
      "set booked_at = #{stamp}
      where trade_id = #{trade_id}"
    )
  end

  def eur_total
    @eur_total ||= multiply(btc, eur_rate)
  end

  def eur_rate
    trade["eur_rate"]
  end

  def btc
    trade["btc"]
  end

  def bidder_id
    trade["bidder_id"]
  end

  def asker_id
    trade["asker_id"]
  end

  def trade
    @trade ||= $db.query("select * from trades where trade_id = #{trade_id} and booked_at is null").first
  end

  def stamp
    @stamp ||= Time.stamp
  end

end
