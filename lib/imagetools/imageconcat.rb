# coding: utf-8

require 'imagetools/version'
require 'rmagick'
require 'optparse'

module Imagetools
  class Imageconcat
    
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
      opt.on('-o OUTNAME', '--output=OUTNAME', 'Output file') {|v| opts[:o] = v}
      opt.on('-n NUM', '--number=NUM', 'Concat image number') {|v| opts[:n] = v.to_i}
      opt.parse!(argv)
      image_files = get_image_files(opts, argv)
      if image_files.size < 2
        puts "Cannot find image files(#{image_files.size})\n"
        puts opt.help
        exit        
      end
      command = Imageconcat.new(opts)
      command.run(image_files)
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
        # ディレクトリが指定されていた場合、指定ディレクトリ内の画像ファイルの最新n個を対象とする
        # 最新の基準は(ファイル名基準)
        match_files = Dir.glob("#{dir}/*.{jpg,jpeg,png}", File::FNM_CASEFOLD).sort
        # 後ろからn個を取得(小さい方の数とする)
        count = [match_files.size, concat_number].min
        image_files = match_files[-count..-1]
      else
        # それ以外は指定された引き数を全て対象とする
        argv.each do |arg|
          arg = File.expand_path(arg)
          if FileTest.file?(arg) && (arg =~ /\.jpe?g$/i || arg =~ /\.png/i)
            image_files << arg
          end
        end
      end
      image_files
    end
    
    def initialize(opts)
      @opts = opts
    end
    
    def run(image_files)
      dirname = File.dirname(image_files[-1])
      output_name = "photo.jpg"
      if @opts[:o]
        output_name = @opts[:o]
      end
      output_path = File.join(dirname, output_name)
      concat_images(image_files, output_path)
    end

    private
    def concat_images(image_files, output_file)
      puts image_files.join("+") + "=#{output_file}"

      # 結果の画像リスト
      result_image_list = Magick::ImageList.new
      
      image_files.each do |image_file|
        # 個別画像の背景色を白に変換
        # 一気に行く方法がないので、ImageListを作成しbackground_colorとflatten_imagesを組み合わる。
        #        image_list = Magick::ImageList.new(image_file) {self.background_color = 'white'}
        # 2022/03/24「passing a block without an image argument is deprecate」対策。 https://github.com/rmagick/rmagick/blob/main/CHANGELOG.md RMagick 4.2.0
        image_list = Magick::ImageList.new(image_file) {|image| image.background_color = 'white'} 
        image = image_list.flatten_images

        # 結果の画像リストに追加
        result_image_list << image
      end

      #append(false)で横方向に結合
      result = result_image_list.append(false)      

      width = result.columns
      height = result.rows

      padding = 10
      if height > 1000
        padding = 20
      end
      
      image_width = width / image_files.size
      result = result.splice(image_width, 0, padding, 0)  # 画像を10字に切る
      if image_files.size > 2
        result = result.splice(image_width * 2 + padding, 0, padding, 0)  # 画像を10字に切るメソッドみたい
      end
      result.write output_file
    end
  end
end
