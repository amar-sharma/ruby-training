require 'bundler/setup'
require 'rack/test'
require_relative "../server_handler"
require_relative "../server"

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure { |c| c.include RSpecMixin }
