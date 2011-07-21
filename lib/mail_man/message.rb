module MailMan
  class Message
    
    REDIS_LIFETIME = 604800 # 7 days, in seconds

    attr_accessor :subject, :tags, :message_id

    MissingFields = Class.new( StandardError )


    def initialize(opts = {})
      @subject    = opts[:subject]
      @message_id = opts[:message_id]
      @tags       = opts[:tags] if ( opts.key?(:tags) && opts[:tags].is_a?(Array) )
    end

    def save!
      raise MissingFields if (subject.nil? || message_id.nil?)

      store_in_redis!
      associate_tags!
      
      self
    end

    def id
      message_id
    end

    def redis_key
      "mesg-#{id}"
    end

    private

    def store_in_redis!
      args = { :subject => subject, :message_id => message_id }.to_a.flatten
      args.unshift( redis_key )
      MailMan.redis.hmset( *args  )
      MailMan.redis.expire redis_key, REDIS_LIFETIME 
    end

    def associate_tags!
      tags.each do |tag|
        MailMan.redis.lpush tag.to_s, redis_key
        MailMan.redis.ltrim tag.to_s, 0, 99
      end
    end
  end
end
