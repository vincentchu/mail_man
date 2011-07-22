require 'sinatra/base'

module MailMan
  class Server < Sinatra::Application

    get '/' do
      " this is root"
    end

    post '/message' do
      begin
        execute_async_if_possible {
          MailMan::Message.new( construct_opts(params) ).save!
        }

        [200, {}, ""]
      rescue => ex
        [400, {}, "Exception: #{ex.message}"]
      end
    end

    private

    def execute_async_if_possible(&block)
      EM.reactor_running? ? EM.next_tick(&block) : block.call
    end

    def construct_opts( params )
      opts = %w(subject message_id tags timestamp).inject({}) { |hash, attr|
        hash[attr.to_sym] = params[attr] if params.key?(attr)
        hash
      }

      opts
    end
  end 
end
