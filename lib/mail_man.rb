require 'redis'

module MailMan

  autoload :Message, 'mail_man/message'
  autoload :Tag, 'mail_man/message'

  def redis
    @redis ||= Redis.new(:host => "localhost", :port => 6379)
  end
end
