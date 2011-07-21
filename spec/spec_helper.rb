$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'mail_man'

$redis = Redis.new(:host => "localhost", :port => 6379)
