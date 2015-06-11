describe Key_server_api do
  
  before(:all) do
    @server = Key_server_api.new(10,100)
  end

  before(:each) do
    20.times {@server.create_key}
  end

  describe '#initialize' do 
    it "sets time" do
      expect(@server.unblock_time).to equal(10)
      expect(@server.delete_time).to equal(100)
    end
  end

  describe '#create_key' do
    it "generates key" do
      @server.purge_all
      @server.create_key
      expect(@server.unblocked_keys).to_not be_nil
  	end
    it "creates random key" do
      expect(@server.create_key).to_not equal(@server.create_key)
    end
  end

  describe '#delete_key' do
    it "deletes an unblocked key" do
      deleting_key = @server.unblocked_keys.keys[1]
      expect(@server.delete_key(deleting_key)).to be true
      expect(@server.unblocked_keys.keys).to_not include(deleting_key)
    end

    it "deletes a blocked key" do
      @server.block_key(@server.unblocked_keys.keys[1])
      deleting_key = @server.blocked_keys.keys[0]
      expect(@server.delete_key(deleting_key)).to be true
      expect(@server.blocked_keys.keys).to_not include(deleting_key)
    end
    it "checks for non-existing key" do
      expect(@server.delete_key("asdmsadnsadadsadas897xawa")).to be false
    end
  end

  describe '#block_key' do
    it "blocks given key" do
      blocking_key = @server.unblocked_keys.keys[0]
      expect(@server.block_key(blocking_key)).to be true 
      expect(@server.blocked_keys.keys).to include(blocking_key)
      expect(@server.unblocked_keys.keys).to_not include(blocking_key)
    end
    it "can't block already blocked key" do
      expect(@server.block_key(@server.blocked_keys.keys[0])).to be false
    end
    it "can't block a deleted key" do
      deleting_key = @server.unblocked_keys.keys[1]
      @server.delete_key(deleting_key)
      expect(@server.block_key(deleting_key)).to be false
    end

    it "can't block an invalid key" do
      expect(@server.block_key("adssadasdasas9e3e23e2asdas")).to be false
    end
  end

  describe "#unblock_key" do
    it "unblocks a key" do
      blocking_key = @server.unblocked_keys.keys[0]
      @server.block_key(blocking_key)
      expect(@server.unblock_key(blocking_key)).to be true
      expect(@server.unblocked_keys.keys).to include(blocking_key)
      expect(@server.blocked_keys.keys).to_not include(blocking_key)
    end
    it "can't unblock a deleted key" do
      deleting_key = @server.unblocked_keys.keys[1]
      @server.delete_key(deleting_key)
      expect(@server.block_key(deleting_key)).to be false
    end

    it "can't unblock an invalid key" do
      expect(@server.unblock_key("adssadasdasas9e3e23e2asdas")).to be false
    end
  end

  describe "#keep_alive" do
    it "keeps a unblocked key alive" do
      alive_key = @server.unblocked_keys.keys[2]
      expect(@server.keep_alive(alive_key)).to be true
      expect(@server.unblocked_keys[alive_key][0].sec).to equal(Time.now.sec)
    end

    it "keeps a blocked key alive" do
      blocking_key = @server.unblocked_keys.keys[0]
      @server.block_key(blocking_key)
      expect(@server.keep_alive(blocking_key)).to be true
      expect(@server.blocked_keys[blocking_key][0].sec).to equal(Time.now.sec)
    end

    it "can't bring a key back from dead" do
      deleting_key = @server.unblocked_keys.keys[1]
      @server.delete_key(deleting_key)
      expect(@server.keep_alive(deleting_key)).to be false
      expect(@server.unblocked_keys[deleting_key]).to be_nil
      expect(@server.blocked_keys[deleting_key]).to be_nil
    end
  end

  describe "#get_key" do
    
    it "gets a key from unblocked keys" do
      expect(@server.get_key).to_not be_nil
    end

    it "gets random key from unblocked_keys and blocks it" do
      got_key = @server.get_key
      expect(got_key).to_not equal(@server.get_key)
      expect(@server.blocked_keys[got_key]).to_not be_nil
    end

    it "doesn't give a blocked_key" do
      got_key = @server.get_key
      expect(@server.blocked_keys[got_key]).to_not equal(@server.get_key)
    end

    it "doesn't give a deleted key" do
      deleting_key = @server.unblocked_keys.keys[1]
      @server.delete_key(deleting_key)
      expect(@server.get_key).to_not be equal(deleting_key)
    end

    it "doesn't give an invalid key" do
      got_key = @server.get_key
      expect(@server.blocked_keys).to include(got_key)
    end

    it "doesn't give just expired key" do
      @server.purge_all
      new_key = @server.create_key
      @server.simulate_auto_delete(new_key,99)
      expect(@server.get_key).to_not eq("404")
      @server.simulate_auto_delete(new_key,1)
      expect(@server.get_key).to eq("403")
    end

    it "doesn't give just going to unblock keys" do
      @server.purge_all
      new_key = @server.create_key
      @server.block_key(new_key)
      @server.simulate_auto_unblock(new_key,9)
      expect(@server.get_key).to eq("403")
    end

    it "gives just unblocked keys" do
      sleep 1
      expect(@server.get_key).to_not eq("404")
    end
  end
end