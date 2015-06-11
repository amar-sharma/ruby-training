require 'securerandom'

class Key_server_api
	attr_accessor :unblocked_keys,:blocked_keys
	attr_reader :unblock_time, :delete_time, :thread
	def initialize(unblock_time,delete_time)
		@unblocked_keys = Hash.new
		@blocked_keys = Hash.new
		@unblock_time = unblock_time
		@delete_time = delete_time
		@thread = Thread.new do
			while true
				sleep 1
				@blocked_keys.keys.each do |key|
					unblock_key(key) if Time.now - @blocked_keys[key][1] > @unblock_time
				end
			end
		end
	end

	def create_key
		new_key = SecureRandom.uuid
		@unblocked_keys[new_key] = [Time.now,Time.now] if @unblocked_keys[new_key]==nil
	end

	def block_key(key)
		if(@unblocked_keys[key] != nil)
			if (Time.now - @unblocked_keys[key][0]) > @delete_time
				@unblocked_keys.delete(key)
				return false
			end
			@blocked_keys[key] = [@unblocked_keys[key][0],Time.now]
			@unblocked_keys.delete(key)
			return true
		else
			return false
		end
	end

	def unblock_key(key)
		if(@blocked_keys[key] != nil)
			if (Time.now - @blocked_keys[key][0]) > @delete_time
				@blocked_keys.delete(key)
				return false
			end
			@unblocked_keys[key] = [@blocked_keys[key][0],Time.now]
			@blocked_keys.delete(key)
		elsif @unblocked_keys[key]!=nil
			puts 'Should be called'
			if (Time.now - @unblocked_keys[key][0]) > @delete_time
				@unblocked_keys.delete(key)
				return false
			end
		else
			return false
		end
		true
	end

	def delete_key(key)
		if @blocked_keys[key] != nil
			@blocked_keys.delete(key)
		elsif @unblocked_keys[key] != nil
			@unblocked_keys.delete(key)
		else
			return false
		end
		true
	end

	def keep_alive(key)
		if(@blocked_keys[key] != nil)
			if (Time.now - @blocked_keys[key][0]) > @delete_time
				@blocked_keys.delete(key)
				return false
			end
			@blocked_keys[key][0] = Time.now
		elsif @unblocked_keys[key]!=nil
			if (Time.now - @unblocked_keys[key][0]) > @delete_time
				@unblocked_keys.delete(key)
				return false
			end
			@unblocked_keys[key][0] = Time.now
		else
			return false
		end
		true
	end

	def print_keys(keys)
		print "\n\n###@@@###\n"
		keys.each do |key|
			puts key
		end
	end

	def get_key
    print "AHHH"
		size = @unblocked_keys.keys.size
		if size!=0
			begin
				hot_key = @unblocked_keys.keys[rand(size)]
				if (Time.now - @unblocked_keys[hot_key][0]) > @delete_time
					@unblocked_keys.delete(hot_key)
          print "AHHH"
					#raise ArgumentError, " Key is Expired!"
				end
			#rescue ArgumentError
			#	retry
			end
			return hot_key
		end
		return "404"
	end
end

if __FILE__ == $0

	k = Key_server_api.new(15,6)
	10.times { k.create_key }
	k.print_keys(k.unblocked_keys)
	while true
		key = gets.chomp
		k.block_key(key)
		k.print_keys(k.blocked_keys)
		k.print_keys(k.unblocked_keys)
		print "\n\t YOYO: #{k.get_key}"
	end
end
