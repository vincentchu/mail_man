module MailMan
  class Message
    
    attr_accessor :subject, :tags, :message_id

    def initialize(opts = {})
      @subject    = opts[:subject]
      @message_id = opts[:message_id]
      @tags       = opts[:tags] if ( opts.key?(:tags) && opts[:tags].is_a?(Array) )
    end

  end
end
