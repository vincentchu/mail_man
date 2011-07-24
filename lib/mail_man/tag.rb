module MailMan
  class Tag

    MissingTagName = Class.new( StandardError ) 

    MAX_REDIS_LIST_LENGTH = 1500
    DAY_IN_SECS           = 86400
    COUNTER_HISTORY       = 30

    attr_reader :name

    def initialize(tag_name)
      raise MissingTagName if tag_name.nil?
      @name = tag_name.to_s
    end

    def summary(opts = {})
      {
        :counts   => construct_counts,
        :messages => self.find( opts )
      }
    end

    def find( opts = {} )
      ind_start, ind_end = construct_pagination_opts( opts )
      message_ids = MailMan.redis.lrange(redis_key, ind_start, ind_end)
    
      fetch_messages_from_ids!( message_ids )
    end

    def total_entries
      MailMan.redis.llen( redis_key )
    end

    def lifetime_counter
      counts = MailMan.redis.lrange(redis_counter_key, 0, -1) || []
      
      counts.collect! do |count|
        data = count.split("/").collect(&:to_i)
        
        [Time.at(data[0]), data[1]]
      end

      pad_counts( counts )
    end

    def increment_lifetime_counter!

      timestamp, count = most_recent_lifetime_count

      if (timestamp == midnight_today)
        count += 1
        MailMan.redis.lset(redis_counter_key, 0, "#{midnight_today}/#{count}")
      else
        MailMan.redis.lpush(redis_counter_key, "#{midnight_today}/1")
      end

      
      MailMan.redis.ltrim(redis_counter_key, 0, COUNTER_HISTORY-1)
    end

    def most_recent_lifetime_count
      most_recent = MailMan.redis.lindex(self.redis_counter_key, 0)
      most_recent = most_recent ? most_recent.split("/").collect(&:to_i) : [nil, nil]

      most_recent
    end

    def redis_key
      name
    end

    def redis_counter_key
      "lifetime_counter_#{name}"
    end

    private

    def pad_counts( counts )

      new_counts = Array.new( COUNTER_HISTORY )
      counts.each do |count|
        timestamp = count.first.to_i
        index = (midnight_today - timestamp) / DAY_IN_SECS

        new_counts[index] = count
      end

      (0..(COUNTER_HISTORY-1)).each do |i|
        next unless new_counts[i].nil?
        
        timestamp = midnight_today - (i*DAY_IN_SECS)
        new_counts[i] = [Time.at(timestamp), 0]
      end

      new_counts
    end

    def construct_counts

      ltime_counts = lifetime_counter
      puts "ltime_counts = #{ltime_counts.inspect}"

      {
        :lifetime_counter => ltime_counts
      }
    end

    def midnight_today
      DAY_IN_SECS * (Time.now.to_i / DAY_IN_SECS)
    end

    def fetch_messages_from_ids!( ids )
      rsp = MailMan.redis.pipelined {
        ids.each do |id|
          MailMan.redis.hgetall( id )
        end
      }

      rsp.collect! do |data|
        MailMan::Message.new( data ) 
      end
    end

    def construct_pagination_opts( opts )
      page     = opts[:page] || 1
      per_page = opts[:per_page] || 10

      ind_start = (page - 1) * per_page
      ind_end   = (page * per_page) - 1

      [ind_start, ind_end]
    end
  end  
end
