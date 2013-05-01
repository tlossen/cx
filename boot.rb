# coding: utf-8
require "rubygems"
require "bundler/setup"
require "redis"
require "mysql2"
require "msgpack"

Root = File.expand_path("..", __FILE__)

%w[monkey . actions workers].each do |dir|
  Dir.glob("lib/#{dir}/*.rb").sort.each do |file|
    puts file
    require_relative file
  end
end

$db = Database.new(
  :host => "localhost",
  :username => "root",
  :database => "test"
)

$redis = Redis.new