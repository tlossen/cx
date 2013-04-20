# require 'redis'
require 'mysql2'

$db = Mysql2::Client.new(
  :host => "localhost",
  :username => "root",
  :database => "test"
)

$db.query "drop table if exists accounts"
$db.query "
  create table accounts (
    account_id  integer primary key auto_increment,
    eur         integer not null default 0,
    eur_used    integer not null default 0,
    btc         integer not null default 0,
    btc_used    integer not null default 0
  )
"
$db.query "drop table if exists orders"
$db.query "
  create table orders (
    order_id    integer primary key auto_increment,
    type        enum('bid', 'ask'),
    eur_limit   integer not null default 0,
    btc         integer not null default 0,
    btc_open    integer not null default 0
  )
"


