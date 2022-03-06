# coding: utf-8
# imagehugo: hugo用の画像処理。リネームとサムネイル&アイキャッチ画像の生成。

require 'imagetools/version'
require 'imagetools/imagefilter'
require 'rmagick'
require 'optparse'
require 'fileutils'

module Imagetools
  class ImageItem
    attr_accessor :srcfile, :dstfile, :outfile
    def to_s
      "#{srcfile}=>#{dstfile}=>#{outfile}"
    end
  end
  
  class Imageblog
    def self.run(argv)
      STDOUT.sync = true
      opts = {}
      opt = OptionParser.new(argv)
      opt.version = VERSION
      opt.banner = "Usage: #{opt.program_name} [-h|--help] <dir> or <image1 image2 image3 ...>"
      opt.separator('')
      opt.separator("Examples:")
      opt.separator("    #{opt.program_name} ~/tmp # concat two recent IMG_*jpg images.")
      opt.separator("    #{opt.program_name} image1.jpg image2.jpg image3.jpg  # concat specified images.")
      opt.separator('')      
      opt.separator("Options:")
      opt.on_head('-h', '--help', 'Show this message') do |v|
        puts opt.help
        exit       
      end
      opt.on('-v', '--verbose', 'Verbose message') {|v| opts[:v] = v}
      opt.on('--dry-run', 'Message only') {|v| opts[:dry_run] = v}
      opt.on('-o OUTDIR', '--output=OUTDIR', 'Output dir') {|v| opts[:o] = v}
      opt.on('-n NUM', '--number=NUM', 'Process image number') {|v| opts[:n] = v.to_i}
      opt.on('-b BASENAME', '--base=BASENAME', 'Output file basename') {|v| opts[:b] = v} 
      opt.parse!(argv)
      opts[:b] ||= Time.now.strftime("%Y%m%d")
      dir, image_files = get_image_files(opts, argv)
      if image_files.size == 0
        puts opt.help
        exit        
      end
      command = Imageblog.new(opts)
      command.run(dir, image_files)
    end

    def self.get_image_files(opts, argv)
      image_files = []
      # ディレクトリが処理対象かどうかを決める
      dir = nil
      if argv.size == 1
        # 引き数が1個の場合は最初の引き数
        path = File.expand_path(argv[0])
        if FileTest.directory?(path)
          dir = path
        end
      elsif argv.size == 0
        # 引き数がない場合カレントディレクトリ
        dir = File.expand_path('.')
      end
      if dir
        concat_number = opts[:n] || 2
        # ディレクトリが指定されていた場合、指定ディレクトリ内のIMG_ファイルの最新n個を対象とする
        # 最新の基準は(ファイル名基準)
        match_files = Dir.glob("#{dir}/*.{jpg,jpeg,png}", File::FNM_CASEFOLD).sort
#        match_files.sort {|a, b|
#          File.mtime(a) <=> File.mtime(b)
#        }
        # 後ろからn個を取得(小さい方の数とする)
        count = [match_files.size, concat_number].min
        image_files = match_files[-count..-1]
      else
        # それ以外は指定された引き数を全て対象とする
        argv.each do |arg|
          arg = File.expand_path(arg)
          dir = File.dirname(arg)
          if FileTest.file?(arg) && (arg =~ /\.jpe?g$/i || arg =~ /\.png/i)
            image_files << arg
          end
        end
      end
      return dir, image_files
    end

    def initialize(opts)
      @opts = opts
    end


    def run(dir, image_files)
      outdir = dir
      if @opts[:o]
        outdir = @opts[:o]
      end
      rename_images(image_files, outdir)
#      concat_images(image_files, output_path)        
    end

    private
    def rename_images(image_files, outdir)
      # サムネイルはhoge_0.jpg
      # アイキャッチはhoge_1.jpg hoge_2.jpg以降が通常の画像
      items = []
      thumbnal_item = nil # hoge_0.jpgとする
      image_files.each_with_index do |image_file, index|
        item = ImageItem.new
        item.srcfile = image_file

        src_basename = File.basename(image_file)
        extname = File.extname(src_basename)
        dst_basename = @opts[:b]

        item.dstfile = File.join(outdir, "#{dst_basename}_#{index + 1}#{extname}")
        if index == 0
          thumbnal_item = ImageItem.new
          thumbnal_item.srcfile = image_file
          thumbnal_item.dstfile = File.join(outdir, "#{dst_basename}_0#{extname}")
        end
        items << item
      end
      items.each do |item|
        FileUtils.cp(item.srcfile, item.dstfile)
      end
      FileUtils.cp(thumbnal_item.srcfile, thumbnal_item.dstfile)

      #フィルタ実行
      config = Config.new
      config.init_default
      opts = {}
      filter = Imagefilter.new(opts, config)
      items.each do |item|
        item.outfile = filter.run(item.dstfile)
      end
      

      # サムネイル
      config.resize_width = 400
      filter = Imagefilter.new(opts, config)
      thumbnal_item.outfile = filter.run(thumbnal_item.dstfile)
      
    end
  end
end
    
