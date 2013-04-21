# coding: utf-8
require "rubygems"
require "bundler/setup"
require "redis"
require "mysql2"

Root = File.expand_path("..", __FILE__)
# $:.unshift("#{Root}/lib")
%w[action].each do |dir|
  Dir.glob("#{dir}/**/*.rb").sort.each { |file| require_relative file }
end

$db = Mysql2::Client.new(
  :host => "localhost",
  :username => "root",
  :database => "test"
)

$redis = Redis.new