require "spec_helper"
require 'json'
describe "server", :server => true do
  before(:all) do
    get "/purge"
  end
  include Rack::Test::Methods
  it "throws 404 when keys are asked without creation" do
    get "/key"
    expect(last_response.status).to eq(403)
    expect(last_response.body).to eq("No unblocked keys available")
  end

  it "creates a key" do
    get "/"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("Key created!")
  end

  it "gives a key on request" do
    get "/key"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to_not eq("404")
  end

  it "deletes a key on request" do
    get "/"
    get "/key"
    delete "/key", "key" => "#{last_response.body}"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("Deleted")
  end

  it "can't delete non existing key" do
    delete "/key", "key" => "asdadnas6sd7as57d56ad"
    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq("No such key exists!")
  end

  it "unblocks a blocked key" do
    get "/"
    get "/key"
    post "/unblock","key" => "#{last_response.body}"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("Unblocked!")
  end

  it "can't unblock a deleted key" do
    get "/"
    get "/key"
    deleting_key = last_response.body
    delete "/key", "key" => "#{deleting_key}"
    post "/unblock","key" => "#{deleting_key}"
    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq("Key unavailable!")
  end

  it "keeps alive a valid key" do
    get "/"
    get "/key"
    alive_key = last_response.body
    patch"/#{alive_key}"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("ok")
  end

  it "can't bring a key back from dead" do
    get "/"
    get "/key"
    deleting_key = last_response.body
    delete "/key", "key" => "#{deleting_key}"
    patch"/#{deleting_key}"
    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq("Key not available!")
  end
end
