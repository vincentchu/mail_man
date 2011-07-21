$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'mail_man'

$redis = Redis.new(:host => "localhost", :port => 6379)

def store_many_mesgs_for!(tag, n = 100)
  n.times.each do |i|
    subj = "message_#{i}"
    mesg_id = "<message.id.is.#{i}@foo.com>"

    MailMan::Message.new(
      :subject    => subj,
      :message_id => mesg_id,
      :tags       => [tag]
    ).save!
  end
end
