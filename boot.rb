# coding: utf-8
require "rubygems"
require "bundler/setup"
require "redis"
require "mysql2"
require "msgpack"

Root = File.expand_path("..", __FILE__)

%w[lib action worker].each do |dir|
  Dir.glob("#{dir}/**/*.rb").sort.each { |file| require_relative file }
end

$db = Database.new(
  :host => "localhost",
  :username => "root",
  :database => "test"
)

$redis = Redis.new