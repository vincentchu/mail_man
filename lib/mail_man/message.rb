module MailMan
  class Message
    
    REDIS_LIFETIME  = 604800 # 7 days, in seconds

    attr_accessor :subject, :tags, :message_id, :timestamp

    MissingFields = Class.new( StandardError )

    def initialize(opts = {})
      if opts.is_a?(Hash)
        initialize_from_hash!( opts ) 
      elsif opts.is_a?(Array)
        initialize_from_array!( opts )
      end

      @tags = [] unless @tags.is_a?(Array)
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
      %w(subject message_id timestamp tags).each do |attr|

        index = array.index( attr )
        next if index.nil?

        val = (attr == "tags") ? array[index+1].split(",") : array[index+1]

        self.send("#{attr}=", val)
      end

      @timestamp = Time.at( timestamp.to_i ) rescue Time.now
    end

    def store_in_redis!
      args = { 
        :subject    => subject,
        :message_id => message_id,
        :timestamp  => timestamp.to_i,
        :tags       => tags.join(",")
      }.to_a.flatten
      
      args.unshift( redis_key )

      MailMan.redis.pipelined {
        MailMan.redis.hmset( *args  )
        MailMan.redis.expire(redis_key, REDIS_LIFETIME)
      }
    end

    def associate_tags!
      tags.each do |tag_name|

        tag = MailMan::Tag.new( tag_name )

        MailMan.redis.lpush(tag.redis_key, redis_key)
        MailMan.redis.ltrim(tag.redis_key, 0, MailMan::Tag::MAX_REDIS_LIST_LENGTH)

        tag.increment_lifetime_counter!
      end
    end
  end
end
