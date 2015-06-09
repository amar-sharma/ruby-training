require "minitest/autorun"
require "./mars_rover"

class Test_rover < Minitest::Test
  def setup
    @plat = Plateau.new(5,5)
    @robot = Robot.new(1,2,'N')
  end

  def test_that_object_exists
    assert_equal Plateau, @plat.class
    assert_equal Robot, @robot.class
  end

  def test_that_bounds
    assert_equal 5 , @plat.x
    assert_equal 5 , @plat.y
  end

  def test_that_robot_is_initialized
    assert_equal 1 , @robot.x
    assert_equal 2 , @robot.y
    assert_equal 'N' , @robot.heading
  end

  def test_that_move_it_works
    assert_equal [1,3],@robot.move_it(@robot.x,@robot.y,@robot.heading)
  end

  def test_that_turn_right_works
    assert_equal 'E',@robot.turn_right(@robot.heading)
    assert_equal 'S',@robot.turn_right('E')
    assert_equal 'W',@robot.turn_right('S')
    assert_equal 'N',@robot.turn_right('W')
  end

  def test_that_turn_left_works
    assert_equal 'W',@robot.turn_left(@robot.heading)
    assert_equal 'N',@robot.turn_left('E')
    assert_equal 'E',@robot.turn_left('S')
    assert_equal 'S',@robot.turn_left('W')
  end

  def test_move
    @robot.move('L',@plat)
    assert_equal [1,2,'W'],[@robot.x,@robot.y,@robot.heading]
    @robot.move('M',@plat)
    assert_equal [0,2,'W'],[@robot.x,@robot.y,@robot.heading]
    @robot.move('R',@plat)
    assert_equal [0,2,'N'],[@robot.x,@robot.y,@robot.heading]
  end

  def test_move_on_string
    "LMRRLMRMM".each_char do |ch|
      @robot.move(ch,@plat)
    end
    assert_equal [2,3,'E'], [@robot.x,@robot.y,@robot.heading]

    "LMMMMM".each_char do |ch|
      @robot.move(ch,@plat)
    end
    assert_equal [2,5,'N'], [@robot.x,@robot.y,@robot.heading]

    "LMMMMMMM".each_char do |ch|
      @robot.move(ch,@plat)
    end
    assert_equal [0,5,'W'], [@robot.x,@robot.y,@robot.heading]

    "LMMMMMMM".each_char do |ch|
      @robot.move(ch,@plat)
    end
    assert_equal [0,0,'S'], [@robot.x,@robot.y,@robot.heading]

    "LMMMMMMM".each_char do |ch|
      @robot.move(ch,@plat)
    end
    assert_equal [5,0,'E'], [@robot.x,@robot.y,@robot.heading]

  end
end