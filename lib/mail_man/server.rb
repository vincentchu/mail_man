require 'sinatra/base'

module MailMan
  class Server < Sinatra::Application

    get '/' do
      " this is root"
    end

    post '/message' do
      begin
        MailMan::Message.new( construct_opts(params) ).save!
        [200, {}, ""]
      rescue => ex
        [400, {}, "Exception: #{ex.message}"]
      end
    end

    private

    def construct_opts( params )
      opts = [:subject, :message_id, :tags, :timestamp].inject({}) { |hash, attr|
        hash[attr] = params[attr] if params.key?(attr)
        hash
      }

      opts
    end
  end 
end
