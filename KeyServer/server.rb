require 'bundler/setup'
require 'sinatra'
require './server_handler'
require './expiry_module'

delete_time = 300;
unblock_time = 30;

handler = KeyServerAPI.new(unblock_time,delete_time)

get '/purge' do
  handler.purge_all
end

get '/' do
  handler.create_key
  "Key created!"
end

get '/key' do
  key=handler.get_key
  if key != "403"
    return key
  else
    status 403
    "No unblocked keys available"
  end

end

delete '/key' do
  if handler.delete_key(params[:key])
    "Deleted"
  else
    status 404
    "No such key exists!"
  end
end

post '/unblock' do
  if handler.unblock_key(params[:key])
    "Unblocked!"
  else
    status 404
    "Key unavailable!"
  end
end

patch '/:key' do
  if handler.keep_alive(params['key'])
    "ok"
  else
    status 404
    "Key not available!"
  end
end
