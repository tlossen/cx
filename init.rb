# coding: utf-8

$db.create_table(:accounts,
  account_id: "integer unsigned primary key auto_increment",
  eur:        "integer unsigned not null default 0",
  eur_used:   "integer unsigned not null default 0",
  btc:        "integer unsigned not null default 0",
  btc_used:   "integer unsigned not null default 0"
)

$db.create_table(:orders,
  order_id:   "integer unsigned primary key auto_increment",
  account_id: "integer unsigned not null",
  type:       "enum('bid', 'ask')",
  eur_limit:  "integer unsigned not null default 0",
  btc:        "integer unsigned not null default 0",
  btc_open:   "integer unsigned not null default 0",
  active:     "boolean not null default true"
)

$db.create_table(:trades,
  trade_id:   "integer unsigned primary key auto_increment",
  bid_id:     "integer unsigned not null",
  ask_id:     "integer unsigned not null",
  eur_rate:   "integer unsigned not null default 0",
  btc:        "integer unsigned not null default 0",
  booked:     "boolean not null default false"
)

