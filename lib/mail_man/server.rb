require 'sinatra/base'

module MailMan
  class Server < Sinatra::Application

    get '/' do
      erb :index
    end

    get "/tags/:id" do
      @tag = MailMan::Tag.new( params[:id] )
      
      begin
        @summary = @tag.summary
      rescue MailMan::Tag::NotFound => ex
        return [404, {}, "We could not find #{@tag.name} anywhere"]
      end
    end

    post '/message' do
      create_message!
    end

    post '/messages' do
      create_message!
    end

    private

    def create_message!
      begin
        execute_async_if_possible {
          MailMan::Message.new( construct_opts(params) ).save!
        }

        [200, {}, ""]
      rescue => ex
        [400, {}, "Exception: #{ex.message}"]
      end
    end

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
