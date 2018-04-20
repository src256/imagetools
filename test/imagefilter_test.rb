require_relative 'test_helper'

class ImagefilterTest < Minitest::Test
  
  def test_replace_screenshot_filename
    result = Imagetools::Imagefilter.replace_screenshot_filename('s 2016-08-16 16.10.29.jpg')
    assert_equal('s_20160816_161029.jpg', result)

    result = Imagetools::Imagefilter.replace_screenshot_filename('abc')
    assert_nil(result)    
  end

  def test_replace_png2jpg
    result = Imagetools::Imagefilter.replace_png2jpg('test.png')
    assert_equal('test.jpg', result)
  end

  def test_exclude_image
    result = Imagetools::Imagefilter.match_exclude_image?('test.png')
    assert(result == nil)

    result = Imagetools::Imagefilter.match_exclude_image?('_test.png')
    assert(result != nil)
  end
end
