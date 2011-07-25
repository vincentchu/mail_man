require 'sinatra/base'
require 'haml'
require 'json'

module MailMan
  class Server < Sinatra::Application

    set :static, true
    set :haml, :format => :html5

    get '/' do
      haml :index
    end

    get "/tags/:id" do
      @tag = MailMan::Tag.new( params[:id] )
      
      begin
        @summary = @tag.summary
        @counts  = @summary[:counts]
        @history = @counts[:lifetime_counter].collect {|c| [(1000 * c.first.to_i), c.last] }
        @mesgs   = @summary[:messages].group_by {|m| round_to_midnight(m.timestamp) }

      rescue MailMan::Tag::NotFound => ex
        return [404, {}, "NotFound"]
      end

      haml :tag
    end

    post '/message' do
      create_message!
    end

    post '/messages' do
      create_message!
    end

    private

    def round_to_midnight( time )
      time_int = MailMan::Tag::DAY_IN_SECS * (time.to_i / MailMan::Tag::DAY_IN_SECS)
      Time.at( time_int )
    end

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
