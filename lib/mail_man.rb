require 'redis'
require 'digest/md5'

module MailMan

  autoload :Message, 'mail_man/message'
  autoload :Tag,     'mail_man/tag'
  autoload :Server,  'mail_man/server'

  extend self

  attr_accessor :environment, :logger

  def redis
    @redis ||= Redis.new(:host => "localhost", :port => 6379)
  end
end
