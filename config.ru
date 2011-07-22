#!/usr/bin/env ruby
require 'logger'

$LOAD_PATH.unshift ::File.expand_path(::File.dirname(__FILE__) + '/lib')
require 'mail_man'

puts "ENV= #{ENV.inspect}"

MailMan.environment = ENV['RACK_ENV']
MailMan.start_em_reactor!

use Rack::ShowExceptions 
# use Rack::CommonLogger, Flowb.logger
run MailMan::Server.new


