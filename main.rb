#! /usr/local/bin/ruby

require "rubygems"
require "gosu"
require "trollop"

$opts = Trollop::options do
	opt :fullscreen, "Use fullscreen"
end

module SpaceDude

private

WIDTH  = 800
HEIGHT = 600

class Coin

	attr_reader :x, :y

	def initialize(x, y)
		@x = x
		@y = y
		@image = Gosu::Image.new "images/Coin.png"
	end

	def draw
		@image.draw @x, @y, 0
	end
end

class Missle

	def initialize(x, y, direction)
		@x = x
		@y = y
		@direction = direction
		@image = Gosu::Image.new "images/Missle.png"
	end

	def update
		@x += Gosu::offset_x(@direction, 10)
    	@y += Gosu::offset_y(@direction, 10)
	end

	def draw
		@image.draw_rot @x, @y, 0, @direction
	end

	def off_screen?
		@x > SpaceDude::WIDTH || @x < 0 || @y > SpaceDude::HEIGHT || @y < 0
	end

	def is_tuching?(x, y)
		Math.sqrt(((x - @x).abs ** 2) + ((y - @y).abs ** 2)) <= 25
	end
end

class SpaceShip

	attr_reader :x, :y, :direction
	
	def initialize
		@x = WIDTH / 2
		@y = HEIGHT / 2
		@direction = 0
		@image = Gosu::Image.new "images/starfighter.png"
	end
	
	def draw
		@image.draw_rot(@x, @y, 0, @direction)
	end

	def update
		@direction -= 4.5 if Gosu::button_down?(Gosu::KbLeft) || Gosu::button_down?(Gosu::KbA)
		@direction += 4.5 if Gosu::button_down?(Gosu::KbRight) || Gosu::button_down?(Gosu::KbD)
		if Gosu::button_down?(Gosu::KbUp) || Gosu::button_down?(Gosu::KbW)
			@x += Gosu::offset_x(@direction, 5)
			@y += Gosu::offset_y(@direction, 5)
		end
		if Gosu::button_down?(Gosu::KbDown) || Gosu::button_down?(Gosu::KbS)
			@x += Gosu::offset_x(@direction, -5)
			@y += Gosu::offset_y(@direction, -5)
		end
		if @x < 0
			@x = 0
		elsif @x > SpaceDude::WIDTH
			@x = SpaceDude::WIDTH
		end
		if @y < 0
			@y = 0
		elsif @y > SpaceDude::HEIGHT
			@y = SpaceDude::HEIGHT
		end
	end

	def is_tuching?(x, y)
		Math.sqrt(((x - @x).abs ** 2) + ((y - @y).abs ** 2)) <= 35
	end
end

class MiniEnemyShip
	
	attr_reader :x, :y

	def initialize(x, y, direction)
		@x = x
		@y = y
		@direction = direction
		@image = Gosu::Image.new "images/starfighter enemy.png"
	end

	def draw
		@image.draw_rot @x, @y, 0, @direction, 0.5, 0.5, 0.5, 0.5
	end

	def update
		@x += Gosu::offset_x(@direction, 8)
    	@y += Gosu::offset_y(@direction, 8)
	end

	def off_screen?
		@x > SpaceDude::WIDTH || @x < 0 || @y > SpaceDude::HEIGHT || @y < 0
	end
end

class EnemyShip

	attr_reader :x, :y

	def initialize(x, y, direction)
		@x = x
		@y = y
		@direction = direction
		@image = Gosu::Image.new "images/starfighter enemy.png"
	end

	def draw
		@image.draw_rot @x, @y, 0, @direction
	end

	def update
		@x += Gosu::offset_x(@direction, 5)
    	@y += Gosu::offset_y(@direction, 5)
	end

	def off_screen?
		@x > SpaceDude::WIDTH || @x < 0 || @y > SpaceDude::HEIGHT || @y < 0
	end
end

class Screen < Gosu::Window
	
	def initialize(muted)
		super WIDTH, HEIGHT, $opts[:fullscreen]
		@ship = SpaceShip.new
		@enemyships = []
		@miniships = []
		@coins = []
		@score = 0
		@font = Gosu::Font.new(20)
		@space = Gosu::Image.new "images/Space.png"
		@game_over = false
		@beep = Gosu::Sample.new "music/beep.wav"
		@music = Gosu::Song.new "music/Cello_Wars.mp3"
		@music.play if !muted
		@paused = false
		@explosion = Gosu::Sample.new "music/explosion.wav"
		@muted = muted
		@missles = []
		@record = File.read("data/Space_Dude_record.txt").to_i
		#@music.play
		self.caption = "Space Dude"
	end
	
	def draw
		@space.draw 0, 0, 0, SpaceDude::WIDTH.to_f / 640.0, SpaceDude::HEIGHT.to_f / 480.0
		@missles.each { |missle| missle.draw }
		@ship.draw
		@miniships.each { |ship| ship.draw }
		@enemyships.each { |ship| ship.draw }
		@coins.each { |coin| coin.draw }
		@font.draw("Score: #{@score}", 10, 10, 0, 1.0, 1.0, 0xff_00ffff)
		@font.draw("Record: #{@record}", 110, 10, 0, 1.0, 1.0, 0xff_00ffff)
		@font.draw("Fps: #{Gosu::fps}", 260, 10, 0, 1.0, 1.0, 0xff_00ffff)
		if @game_over
			@font.draw("Game Over", 345, 280, 0, 1.0, 1.0, 0xff_ff0000)
			if @score > @record
				@font.draw("New Record!", 341, 300, 0, 1.0, 1.0, 0xff_00ffff)
				File.open("data/Space_Dude_record.txt", "w") do |f| 
					f.write @score
				end
			end
		end
	end

	def update
		if Gosu::button_down? Gosu::KbP
			@paused = !@paused
			if @paused == true
				@music.pause
			else
				if !@muted
					@music.play
				end
			end
			sleep 0.1
		end
		if Gosu::button_down? Gosu::KbM
			@muted = !@muted
			if @muted
				@music.pause
			else
				@music.play	
			end
			sleep 0.1
		end
		if !@paused
			if @game_over
				#@music.stop
				sleep 1
				initialize @muted
			end
			@ship.update
			if Gosu::button_down?(Gosu::KbSpace)
				@missles.push Missle.new @ship.x, @ship.y, @ship.direction
				if @score >= 100000000
					@missles.push Missle.new @ship.x, @ship.y, @ship.direction - 10
					@missles.push Missle.new @ship.x, @ship.y, @ship.direction + 10
				end
				if @score >= 1000000
					@missles.push Missle.new @ship.x, @ship.y, @ship.direction + 170
					@missles.push Missle.new @ship.x, @ship.y, @ship.direction - 180
					@missles.push Missle.new @ship.x, @ship.y, @ship.direction + 190
				end
			end
			@missles.each do |missle|
				missle.update
				if missle.off_screen?
					@missles.delete missle
				end
			end
			@enemyships.each do |ship|
				ship.update
				if @ship.is_tuching?(ship.x, ship.y)
					@game_over = true
					@explosion.play
					return
				end
				if ship.off_screen?
					@enemyships.delete ship
				end
				@missles.each do |missle|
					if missle.is_tuching? ship.x, ship.y
						@enemyships.delete ship
						@missles.delete missle
						@score += 5
						@explosion.play
						break
					end
				end
			end
			@miniships.each do |ship|
				ship.update
				if @ship.is_tuching?(ship.x, ship.y)
					@game_over = true
					@explosion.play
					return
				end
				if ship.off_screen?
					@enemyships.delete ship
				end
				@missles.each do |missle|
					if missle.is_tuching? ship.x, ship.y
						@miniships.delete ship
						@missles.delete missle
						@score += 20
						@explosion.play
						break
					end
				end
			end
			if rand(100) == 0 # Enemy ship
				rand_num = rand 4
				if rand_num == 0 # left
					direction = 90
					new_x = 1
					new_y = rand SpaceDude::HEIGHT
				elsif rand_num == 1 # bottom
					direction = 0
					new_x = rand SpaceDude::WIDTH
					new_y = SpaceDude::HEIGHT
				elsif rand_num == 2 # right
					direction = 270
					new_x = SpaceDude::WIDTH
					new_y = rand SpaceDude::HEIGHT
				else # top
					direction = 180
					new_x = rand SpaceDude::WIDTH
					new_y = 1
				end
				@enemyships.push EnemyShip.new(new_x, new_y, direction)
			end
			if rand(200) == 0 # Mini ship
				rand_num = rand 4
				if rand_num == 0 # left
					direction = 90
					new_x = 1
					new_y = rand SpaceDude::HEIGHT
				elsif rand_num == 1 # bottom
					direction = 0
					new_x = rand SpaceDude::WIDTH
					new_y = SpaceDude::HEIGHT
				elsif rand_num == 2 # right
					direction = 270
					new_x = SpaceDude::WIDTH
					new_y = rand SpaceDude::HEIGHT
				else # top
					direction = 180
					new_x = rand SpaceDude::WIDTH
					new_y = 1
				end
				@miniships.push MiniEnemyShip.new(new_x, new_y, direction)
			end
			if @coins.length < 25 && rand(100) == 0
				@coins.push Coin.new rand(WIDTH - 20), rand(HEIGHT - 20)
			end
			@coins.each do |coin|
				if @ship.is_tuching? coin.x, coin.y
					@coins.delete coin
					@score += 10
					@beep.play if !@muted
				end
			end
		end
	end
end

end

SpaceDude::Screen.new(false).show if __FILE__ == $0