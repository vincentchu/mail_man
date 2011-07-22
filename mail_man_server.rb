#!/usr/bin/env ruby
# encoding: utf-8

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), './lib'))

require 'rubygems'
require 'goliath'
require 'mail_man'

[MailMan::Message, MailMan::Tag, Goliath::API, Goliath::Application, Goliath::Rack].each do |klass|
  puts "kass = #{klass.inspect}"
end

class CreateMessage < Goliath::API
  use Goliath::Rack::Params

  def save_message!(prms)
    prms = prms
    EM.defer {
      MailMan::Message.new(
        :subject    => prms["subject"],
        :message_id => prms["message_id"],
        :tags       => prms["tags"]
      ).save!
    }
  end

  def response(env)
    save_message!( params )

    [200, {}, ""]
  end
end

class MailManServer < Goliath::API
  use ::Rack::Reloader, 0 if Goliath.dev? 

  post "/message" do
    run CreateMessage.new
  end

  get "/" do
    run Proc.new { |env| [404, {"Content-Type" => "text/html"}, ["This is the root"]] }
  end

  # not_found('/') do
  #   run Proc.new { |env| [404, {"Content-Type" => "text/html"}, ["Not Found!"]] }
  # end

  # You must use either maps or response, but never both!
  def response(env)
    raise RuntimeException.new("#response is ignored when using maps, so this exception won't raise. See spec/integration/rack_routes_spec.")
  end
end
