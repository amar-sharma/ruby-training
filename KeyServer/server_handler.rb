require 'securerandom'

class Key_server_api
	attr_accessor :unblocked_keys,:blocked_keys
	attr_reader :unblock_time, :delete_time
	def initialize(unblock_time,delete_time)
		@unblocked_keys = Hash.new
		@blocked_keys = Hash.new
		@unblock_time = unblock_time
		@delete_time = delete_time
		@mutex = Mutex.new
		thread = Thread.new do
			while true
				sleep 1
				@mutex.synchronize do
					@blocked_keys.keys.each do |key|
						if Time.now - @blocked_keys[key][1] > @unblock_time
							unblock_key(key)
						else
							break
						end
					end
				end
			end
		end
	end

	def create_key
		begin
			new_key = SecureRandom.uuid
			if @unblocked_keys[new_key]!=nil
				raise StandardError, "Key already"
			end
			@unblocked_keys[new_key] = [Time.now,Time.now]
			new_key
		rescue StandardError => e
			retry
		end
	end

	def block_key(key)
		@mutex.synchronize do
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
	end

	def unblock_key(key)
		@mutex.synchronize do
			if(@blocked_keys[key] != nil)
				if (Time.now - @blocked_keys[key][0]) > @delete_time
					@blocked_keys.delete(key)
					return false
				end
				@unblocked_keys[key] = [@blocked_keys[key][0],Time.now]
				@blocked_keys.delete(key)
			elsif @unblocked_keys[key]!=nil
				if (Time.now - @unblocked_keys[key][0]) > @delete_time
					@unblocked_keys.delete(key)
					return false
				end
			else
				return false
			end
		end
		true
	end

	def delete_key(key)
		@mutex.synchronize do
			if @blocked_keys[key] != nil
				@blocked_keys.delete(key)
			elsif @unblocked_keys[key] != nil
				@unblocked_keys.delete(key)
			else
				return false
			end
		end
		true
	end

	def keep_alive(key)
		@mutex.synchronize do
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
		end
		true
	end

	def get_key
		begin
			size = @unblocked_keys.keys.size
			if size!=0
				hot_key = @unblocked_keys.keys[rand(size)]
				if !block_key(hot_key)
					raise ArgumentError, " Key is Expired!"
				end
				return hot_key
			else
				return "403"
			end
			rescue ArgumentError
				retry
		end
	end

	# Test helper method to simulate auto unblock by increasing key's age
	def simulate_auto_unblock(key,sec)
		@blocked_keys[key][1] -= sec
	end

	# Test helper method to simulate auto delete by increasing key's age
	def simulate_auto_delete(key,sec)
		if @unblocked_keys[key]!=nil
			@unblocked_keys[key][0] -= sec
		elsif @blocked_keys[key]!=nil
			@blocked_keys[key][0] -= sec
		end
	end

	# Test helper to purge all keys
	def purge_all
		@unblocked_keys={}
		@blocked_keys={}
	end

	private
	def print_keys(keys)
		print "\n\n######\n"
		keys.each do |key|
			puts key
		end
		print "\n\n######\n"
	end
end

if __FILE__ == $0

	k = Key_server_api.new(15,10)
	10.times { k.create_key }
	k.print_keys(k.unblocked_keys)
	while true
		key = gets.chomp
		k.block_key(key)
		k.print_keys(k.blocked_keys)
		k.print_keys(k.unblocked_keys)
		print "\n\t Key got: #{k.get_key}"
	end
end
