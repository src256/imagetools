require_relative 'test_helper'

class ImagefilterTest < Minitest::Test
  
  def test_replace_image_filename
    result = Imagetools::Imagefilter.replace_image_filename('s 2016-08-16 16.10.29.jpg')
    assert_equal('s_20160816_161029.jpg', result)

    result = Imagetools::Imagefilter.replace_image_filename('s 2016-08-16 16.10.29.png')
    assert_equal('s_20160816_161029.png', result)    

    result = Imagetools::Imagefilter.replace_image_filename('abc')
    assert_nil(result)


    result = Imagetools::Imagefilter.replace_image_filename('test.large')
    assert_equal(result, 'test.jpg')
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
