require 'spec_helper'
require 'sinatra/base'
require 'rack/test'

MailMan.environment = ENV['RACK_ENV']
