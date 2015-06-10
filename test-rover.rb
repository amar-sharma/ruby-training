require "minitest/autorun"
require "./mars_rover"

class Test_rover < Minitest::Test
  def setup
    @plat = Plateau.new(5,5)
    @robot = Robot.new(1,2,'N',@plat)
  end
  def test_plateau_inputs
    assert_raises(ArgumentError) {Plateau.new(5,-5)}
    assert_raises(ArgumentError) {Plateau.new(-5,-5)}
    assert_raises(ArgumentError) {Plateau.new(-5,5)}
    assert_raises(ArgumentError) {Plateau.new('w',-5)}
    assert_raises(ArgumentError) {Plateau.new(5,'e')}
  end

  def test_that_object_exists
    assert_equal Plateau, @plat.class
    assert_equal Robot, @robot.class
  end

  def test_that_bounds
    assert_equal 5 , @plat.x
    assert_equal 5 , @plat.y
  end

  def test_robot_inputs
    assert_raises(ArgumentError) {Robot.new(1,-2,"N")}
    assert_raises(ArgumentError) {Robot.new(-1,2,"N")}
    assert_raises(ArgumentError) {Robot.new(6,-2,"N")}
    assert_raises(ArgumentError) {Robot.new(1,6,"N")}
    assert_raises(ArgumentError) {Robot.new('g',-2,"N")}
    assert_raises(ArgumentError) {Robot.new(1,'x',"N")}
    assert_raises(ArgumentError) {Robot.new(1,-2,"R")}
    assert_raises(ArgumentError) {Robot.new(1,-2,5)}
  end
  def test_that_robot_is_initialized
    assert_equal 1 , @robot.x
    assert_equal 2 , @robot.y
    assert_equal 'N' , @robot.heading
    assert_equal Plateau, @robot.plateau.class
  end

  def test_that_ahead_works
    assert_equal [1,3,'N'],@robot.ahead(@robot.x,@robot.y,@robot.heading)
  end

  def test_that_turn_works
    assert_equal 'E',@robot.turn("R",@robot.heading)[2]
    assert_equal 'S',@robot.turn("R",'E')[2]
    assert_equal 'W',@robot.turn("R",'S')[2]
    assert_equal 'N',@robot.turn("R",'W')[2]

    assert_equal 'W',@robot.turn("L",@robot.heading)[2]
    assert_equal 'N',@robot.turn("L",'E')[2]
    assert_equal 'E',@robot.turn("L",'S')[2]
    assert_equal 'S',@robot.turn("L",'W')[2]
  end

  def test_move
    @robot.move('L')
    assert_equal [1,2,'W'],[@robot.x,@robot.y,@robot.heading]
    @robot.move('M')
    assert_equal [0,2,'W'],[@robot.x,@robot.y,@robot.heading]
    @robot.move('R')
    assert_equal [0,2,'N'],[@robot.x,@robot.y,@robot.heading]
    @robot.move("LMRRLMRMM")
    assert_equal [2,3,'E'], [@robot.x,@robot.y,@robot.heading]
    @robot.move("LMMMMM")
    assert_equal [2,5,'N'], [@robot.x,@robot.y,@robot.heading]
    @robot.move("LMMMMMMM")
    assert_equal [0,5,'W'], [@robot.x,@robot.y,@robot.heading]
    @robot.move("LMMMMMM")
    assert_equal [0,0,'S'], [@robot.x,@robot.y,@robot.heading]
    @robot.move("LMMMMM")
    assert_equal [5,0,'E'], [@robot.x,@robot.y,@robot.heading]
  end
end