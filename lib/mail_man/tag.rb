module MailMan
  class Tag

    MissingTagName = Class.new( StandardError ) 
    MAX_REDIS_LIST_LENGTH = 1500

    attr_reader :name

    def initialize(tag_name)
      raise MissingTagName if tag_name.nil?
      @name = tag_name.to_s
    end

    def find( opts = {} )

      ind_start, ind_end = construct_pagination_opts( opts )
      message_ids = MailMan.redis.lrange(name, ind_start, ind_end)
    
      fetch_messages_from_ids!( message_ids )
    end

    def total_entries
      MailMan.redis.llen( name )
    end

    def lifetime_counter
      counts = MailMan.redis.lrange("lifetime_counter_#{name}", 0, -1) || []

      counts.collect! do |count|
        data = count.split("/").collect(&:to_i)
        
        [Time.at(data[0]), data[1]]
      end
    end

    private

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
