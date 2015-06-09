class Plateau
	attr_reader :x,:y
	def initialize(x,y)
		@x = x
		@y = y
	end
end

class Robot
	attr_accessor :x,:y,:heading
	def initialize(x,y,heading)
		@x = x
		@y = y
		@heading = heading
	end

	def move_it(x,y,h)
		case h
			when 'N'
				y += 1
			when 'S'
				y -= 1
			when 'E'
				x += 1
			when 'W'
				x -= 1
			else
				puts 'Error'
		end
		return x,y
	end

	def turn_right(h)
		case h
			when 'N'
				h = 'E'
			when 'S'
				h = 'W'
			when 'E'
				h = 'S'
			when 'W'
				h = 'N'
			else
				puts 'Error'
		end
		h
	end

	def turn_left(h)
		case h
			when 'N'
				h = 'W'
			when 'S'
				h = 'E'
			when 'E'
				h = 'N'
			when 'W'
				h = 'S'
			else
				puts 'Error'
		end
		h
	end

	def move(direction,plateau)
		x = self.x
		y = self.y
		h = self.heading
		case direction
			when 'M'
				x,y=move_it(x,y,h) 
			when 'L'
				h = turn_left(h)
			when 'R'
				h = turn_right(h)
			else
				puts ' Error'
		end
		self.x = x if x <= plateau.x && x >= 0 #Checking bounds on X
		self.y = y if y <= plateau.y && y >= 0 #Checking bounds on Y
		self.heading = h
	end
end

=begin 
 Assuming rovers can overlap each other.
 running program by this command
 ruby mars_rover.rb
=end
