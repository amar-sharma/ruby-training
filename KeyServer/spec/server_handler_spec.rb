describe Key_server_api, :helper => true  do
  
  before(:all) do
    @server = Key_server_api.new(10,100)
  end

  before(:each) do
    @server.purge_all
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
      expect(@server.db.get_first_value("Select count(*) from unblocked_keys")).to eq(1);
  	end
    it "creates random key" do
      expect(@server.create_key).to_not equal(@server.create_key)
    end
  end

  describe '#delete_key' do
    it "deletes an unblocked key" do
      @server.purge_all
      @server.create_key
      deleting_key = @server.db.get_first_value("Select * from unblocked_keys")
      expect(@server.delete_key(deleting_key)).to be true
      expect(@server.is_available(deleting_key,'unblocked_keys')).to be false
    end

    it "deletes a blocked key" do
      deleting_key = @server.db.get_first_value("Select * from unblocked_keys")
      @server.block_key(deleting_key)
      expect(@server.delete_key(deleting_key)).to be true
      expect(@server.is_available(deleting_key,'blocked_keys')).to be false
    end
    it "checks for non-existing key" do
      expect(@server.delete_key("asdmsadnsadadsadas897xawa")).to be false
    end
  end

  describe '#block_key' do
    it "blocks given key" do
      blocking_key = @server.db.get_first_value("Select * from unblocked_keys")
      expect(@server.block_key(blocking_key)).to be true 
      expect(@server.is_available(blocking_key,'blocked_keys')).to be true
      expect(@server.is_available(blocking_key,'unblocked_keys')).to be false
    end
    it "can't block already blocked key" do
      blocking_key = @server.db.get_first_value("Select * from blocked_keys")
      expect(@server.block_key(blocking_key)).to be false
    end
    it "can't block a deleted key" do
      deleted_key = @server.db.get_first_value("Select * from unblocked_keys")
      @server.delete_key(deleted_key);
      expect(@server.block_key(deleted_key)).to be false
    end

    it "can't block an invalid key" do
      expect(@server.block_key("adssadasdasas9e3e23e2asdas")).to be false
    end
  end

  describe "#unblock_key" do
    it "unblocks a key" do
      blocking_key = @server.db.get_first_value("Select * from unblocked_keys")
      @server.block_key(blocking_key)
      expect(@server.unblock_key(blocking_key)).to be true
      expect(@server.is_available(blocking_key,'unblocked_keys')).to be true
      expect(@server.is_available(blocking_key,'blocked_keys')).to be false
    end
    it "can't unblock a deleted key" do
      deleting_key = @server.db.get_first_value("Select * from unblocked_keys")
      @server.delete_key(deleting_key)
      expect(@server.block_key(deleting_key)).to be false
    end

    it "can't unblock an invalid key" do
      expect(@server.unblock_key("adssadasdasas9e3e23e2asdas")).to be false
    end
  end

  describe "#keep_alive" do
    it "keeps an unblocked key alive" do
      alive_key = @server.db.get_first_value("Select * from unblocked_keys")
      expect(@server.keep_alive(alive_key)).to be true
      expect(@server.db.get_first_row("Select * from unblocked_keys where key_value = '#{alive_key}'")[1].to_i).to equal(Time.now.to_i+100)
    end

    it "keeps a blocked key alive" do
      blocking_key = @server.db.get_first_value("Select * from unblocked_keys")
      @server.block_key(blocking_key)
      expect(@server.keep_alive(blocking_key)).to be true
    end

    it "can't bring a key back from dead" do
      deleting_key = @server.db.get_first_value("Select * from unblocked_keys")
      @server.delete_key(deleting_key)
      expect(@server.keep_alive(deleting_key)).to be false
      expect(@server.is_available(deleting_key,'unblocked_keys')).to be false
      expect(@server.is_available(deleting_key,'blocked_keys')).to be false
    end
  end

  describe "#get_key" do

    it "gets a key from unblocked keys" do
      expect(@server.get_key).to_not be_nil
    end

    it "gets random key from unblocked_keys and blocks it" do
      got_key = @server.get_key
      expect(got_key).to_not eq("403")
      expect(@server.is_available(got_key,'unblocked_keys')).to be false
      expect(@server.is_available(got_key,'blocked_keys')).to be true
    end

    it "doesn't give a blocked_key" do
      @server.purge_all
      @server.create_key
      @server.get_key
      expect(@server.get_key).to eq("403")
    end

    it "doesn't give a deleted key" do
      @server.create_key
      deleting_key = @server.db.get_first_value("Select * from unblocked_keys")
      @server.delete_key(deleting_key)
      expect(@server.get_key).to_not be equal(deleting_key)
    end

    it "doesn't give an invalid key" do
      @server.purge_all
      key = @server.create_key
      expect(@server.get_key).to eq(key)
    end

    it "doesn't give just expired key" do
      @server.purge_all
      new_key = @server.create_key
      @server.simulate_auto_delete(new_key,99)
      expect(@server.get_key).to_not eq("403")
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
      expect(@server.get_key).to_not eq("403")
    end
  end
end
