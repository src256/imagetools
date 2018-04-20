require_relative "test_helper"

class IconcreatorTest < Minitest::Test
#  def test_that_it_has_a_version_number
#    refute_nil ::Iconcreator::VERSION
#  end
#
#  def test_it_does_something_useful
#    assert false
  #  end
  def test_realsize
    result = Imagetools::Iconcreator.realsize("20x20", "2x")
    assert_equal(40, result)    
    result = Imagetools::Iconcreator.realsize("20x20", "1x")
    assert_equal(20, result)
    result = Imagetools::Iconcreator.realsize("20x20", "3x")
    assert_equal(60, result)
    result = Imagetools::Iconcreator.realsize("83.5x83.5", "2x")
    assert_equal(167, result)    
  end
end
