# coding: utf-8

require 'imagetools/version'
require 'optparse'
require 'rmagick'

module Imagetools
  class Imageresizer
    def self.run(argv)
      STDOUT.sync = true
      opts = {}
      opt = OptionParser.new(argv)
      opt.banner = "Usage: #{opt.program_name} [-h|--help] <args>"
      opt.version = VERSION
      opt.separator('')      
      opt.separator("Options:")
      opt.on_head('-h', '--help', 'Show this message') do |v|
        puts opt.help
        exit
      end
      opt.on('-v', '--verbose', 'Verbose message') {|v| opts[:v] = v}
      opt.on('--dry-run', 'Message only') {|v| opts[:dry_run] = v}
      opt.on('-o OUTNAME', '--output=OUTNAME', 'Output file') {|v| opts[:o] = v}      
      opt.parse!(argv)
      image_files = get_image_files(argv)
      if image_files.size < 1
        puts opt.help
        exit                
      end
      command = Imageresizer.new(opts)
      command.run(image_files[0])  
    end

    def self.get_image_files(argv)
      image_files = []
      argv.each do |arg|
        arg = File.expand_path(arg)
        if FileTest.file?(arg) && (arg =~ /\.jpe?g$/i || arg =~ /\.png/i)
          image_files << arg
        end        
      end
      image_files
    end
    
    def initialize(opts)
      @opts = opts
    end

    def run(image_file)
      imgdata = File.binread(image_file)
      resultdata = center_and_pad(imgdata, 960, 640, 'white', ::Magick::CenterGravity)
      
      outpath = @opts[:o] || 'image.png'
      puts "write to #{outpath}"
      File.binwrite("image.png", resultdata)
    end

    private
    def center_and_pad(imgdata, width, height, background=:transparent, gravity=::Magick::CenterGravity)
      img = Magick::Image.from_blob(imgdata).first

      img = img.resize_to_fit(600, 600)

      new_img = ::Magick::Image.new(width, height)
      if background == :transparent
        filled = new_img.matte_floodfill(1, 1)
      else
        filled = new_img.color_floodfill(1, 1, ::Magick::Pixel.from_color(background))
      end
      filled.composite!(img, gravity, ::Magick::OverCompositeOp)
    # destroy_image(img)
    # filled = yield(filled) if block_given?
    # filled
#    filled.write new_img_path
      filled.format = "png"
      filled.to_blob
    end
  end
end
pp

