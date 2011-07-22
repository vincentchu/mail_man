require 'redis'
require 'eventmachine'

module MailMan

  autoload :Message, 'mail_man/message'
  autoload :Tag,     'mail_man/tag'
  autoload :Server,  'mail_man/server'

  extend self

  attr_accessor :environment, :logger

  def redis
    @redis ||= Redis.new(:host => "localhost", :port => 6379)
  end

  def start_em_reactor!
    require("mail_man/event_machine")
  end
end
