#!/usr/bin/env ruby
require 'logger'

$LOAD_PATH.unshift ::File.expand_path(::File.dirname(__FILE__) + '/lib')
require 'mail_man'

MailMan.environment = ENV['RACK_ENV']
MailMan.start_em_reactor! if (MailMan.environment == "production")

use Rack::Static, :urls => ['/images', '/js', '/css'], :root => 'public'
use Rack::ShowExceptions 
run MailMan::Server.new


