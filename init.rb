# coding: utf-8

$db.create_table("accounts",
  account_id:  "integer primary key auto_increment",
  eur:         "integer unsigned not null default 0",
  eur_used:    "integer unsigned not null default 0",
  btc:         "integer unsigned not null default 0",
  btc_used:    "integer unsigned not null default 0"
)

$db.create_table("orders",
  order_id:    "integer primary key auto_increment",
  type:        "enum('bid', 'ask')",
  eur_limit:   "integer unsigned not null default 0",
  btc:         "integer unsigned not null default 0",
  btc_open:    "integer unsigned not null default 0",
  active:      "boolean not null default true"
)


