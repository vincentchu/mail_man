module MailMan
  class Message
    
    REDIS_LIFETIME  = 604800 # 7 days, in seconds
    DAY_IN_SECS     = 86400
    COUNTER_HISTORY = 30

    attr_accessor :subject, :tags, :message_id, :timestamp

    MissingFields = Class.new( StandardError )

    def initialize(opts = {})
      if opts.is_a?(Hash)
        initialize_from_hash!( opts ) 
      elsif opts.is_a?(Array)
        initialize_from_array!( opts )
      end
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

    def initialize_from_hash!( opts )
      @subject    = opts[:subject]
      @message_id = opts[:message_id]
      @tags       = ( opts.key?(:tags) && opts[:tags].is_a?(Array) ) ? opts[:tags] : []
      @timestamp  = (opts[:timestamp] || Time.now)
    end

    def initialize_from_array!( array )
      %w(subject message_id timestamp).each do |attr|

        index = array.index( attr )
        next if index.nil?

        self.send("#{attr}=", array[index+1])
      end

      timestamp = Time.now if timestamp.nil?
    end

    def store_in_redis!
      args = { :subject => subject, :message_id => message_id }.to_a.flatten
      args.unshift( redis_key )

      MailMan.redis.pipelined {
        MailMan.redis.hmset( *args  )
        MailMan.redis.expire(redis_key, REDIS_LIFETIME)
      }
    end

    def associate_tags!
      tags.each do |tag|
        MailMan.redis.lpush(tag.to_s, redis_key)
        MailMan.redis.ltrim(tag.to_s, 0, MailMan::Tag::MAX_REDIS_LIST_LENGTH)
        increment_lifetime_counter!(tag)  
      end
    end

    def increment_lifetime_counter!(tag)
   
      key = "lifetime_counter_#{tag}"
      most_recent = MailMan.redis.lindex(key, 0)
      most_recent = most_recent ? most_recent.split("/").collect(&:to_i) : ["XX", "XX"]
      
      if most_recent[0] == midnight_time
        count = most_recent[1] + 1
        MailMan.redis.lset(key, 0, "#{midnight_time}/#{count}")
      else
        MailMan.redis.lpush(key, "#{midnight_time}/1")
      end

      MailMan.redis.ltrim(key, 0, COUNTER_HISTORY-1)
    end

    def midnight_time
      DAY_IN_SECS * (Time.now.to_i / DAY_IN_SECS)
    end

  end
end
