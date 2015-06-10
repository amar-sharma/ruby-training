class Plateau
	attr_reader :x,:y
	def initialize(x,y)
		raise ArgumentError, " Co-ordinates for Plateau should be positive" unless ( input_sanitization(x,y) )
		@x = x
		@y = y
	end

	def input_sanitization(x,y)
		(x >= 0 && y >= 0 && (x.is_a? Numeric) && (y.is_a? Numeric))
	end
end

class Robot
	attr_accessor :x,:y,:heading
	attr_reader :plateau
	def heading_check(h)
		h == 'N' || h == 'E' || h == 'W' || h == 'S'
	end

	def initialize(x,y,heading,plateau)
		raise ArgumentError, " Rover position Invalid!" unless ( plateau.input_sanitization(x,y) && heading_check(heading) )
		@plateau = plateau
		@x = x
		@y = y
		@heading = heading
	end

	def ahead(x,y,h)
		begin
			x1 = x
			y1 = y
			case h
				when 'N'
					y += 1
				when 'S'
					y -= 1
				when 'E'
					x += 1
				when 'W'
					x -= 1
			end
			raise RuntimeError, " Rover went off the Plateau!" unless (plateau.input_sanitization(x,y) && heading_check(heading) && (x <= self.plateau.x && y <= self.plateau.y))
		rescue RuntimeError
			puts " Rover flying away! Ignored last move!"
			return [x1,y1,h]
		end
		[x,y,h]
	end

	def turn(direction,h)
		begin
			case direction
				when "L"
					h = find_new_heading(-1,h)
				when "R"
					h = find_new_heading(1,h)
				else
					raise ArgumentError, " Invalid direction!"
			end
		rescue ArgumentError
			puts "Invalid direction! Rover has ignored turn"
		end
		[@x,@y,h]
	end

	def move(directions)
		directions.each_char do |direction|
			@x,@y,@heading = case direction
				when "M"
					ahead(x,y,@heading) 
				else
					turn(direction,@heading)
			end
		end
		[@x,@y,@heading]
	end

	private
	def find_new_heading(x,h)
		compass = ["N","E","S","W"]
		x = (compass.index(h) == 3 && x == 1 )? -3 : x
		compass[compass.index(h) + x]
	end
end

class Navigate
	attr_accessor :plat, :rovers
	def initialize(plateau_x,plateau_y)
		@plat = Plateau.new(plateau_x,plateau_y)
		@rovers = []
	end

	def insert_rover(x,y,h)
		@rover << Robot.new(x,y,h)
	end

	def main()
		rover = Robot.new(0,0,'N',@plat)
		rover_inp = true
		STDIN.each_line do |line|
			if rover_inp
				r = line.split(" ")
				r_x,r_y,h = r[0].to_i,r[1].to_i,r[2]
				rover = Robot.new(r_x,r_y,h,@plat)
				rover_inp = false
			else
				x,y,h = rover.move(line.chomp)
				puts "#{x} #{y} #{h}"
				rover_inp = true
			end
		end
		
	end
end

if __FILE__==$0
	
	begin
		plat = gets.chomp.split(" ")
		p_x,p_y = plat[0].to_i,plat[1].to_i
		nav = Navigate.new(p_x,p_y)
	rescue ArgumentError
		print 'Retry!'
		retry
	end
	nav.main()
end

=begin 
 Assuming rovers can overlap each other.
 running program by this command
 ruby mars_rover.rb or ruby mars_rover.rb < input.txt
=end
