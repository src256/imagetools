require_relative 'test_helper'

class ImagefilterTest < Minitest::Test
  
  def test_replace_image_filename
    config = Imagetools::Config.new
    config.init_default
    result = Imagetools::Imagefilter.replace_image_filename('s 2016-08-16 16.10.29.jpg', config.filename_patterns)
    assert_equal('s_20160816_161029.jpg', result)

    result = Imagetools::Imagefilter.replace_image_filename('s 2016-08-16 16.10.29.png', config.filename_patterns)
    assert_equal('s_20160816_161029.png', result)    

    result = Imagetools::Imagefilter.replace_image_filename('abc', config.filename_patterns)
    assert_equal(result, 'abc')

    result = Imagetools::Imagefilter.replace_image_filename('test.large', config.filename_patterns)
    assert_equal(result, 'test.jpg')
  end

  # def test_replace_png2jpg
  #   result = Imagetools::Imagefilter.replace_png2jpg('test.png')
  #   assert_equal('test.jpg', result)
  # end

  def test_exclude_image
    result = Imagetools::Imagefilter.match_exclude_image?('test.png')
    assert(result == nil)

    result = Imagetools::Imagefilter.match_exclude_image?('_test.png')
    assert(result != nil)
  end

  def test_replace_image2webp
    filename = 'test.png'
    result = Imagetools::Imagefilter.replace_image2webp(filename)
    assert_equal('test.webp', result)

    filename = 'test.jpg'
    result = Imagetools::Imagefilter.replace_image2webp(filename)
    assert_equal('test.webp', result)

    filename = 'test.webp'
    result = Imagetools::Imagefilter.replace_image2webp(filename)
    assert_equal('test.webp', result)

    filename = 'test.WEBP'
    result = Imagetools::Imagefilter.replace_image2webp(filename)
    assert_equal('test.WEBP', result)

  end
end
