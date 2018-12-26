# coding: utf-8

require 'imagetools/version'
require 'optparse'

module Imagetools
  class Imageburst
    
    BASE_FOLDER = "~/Documents/capture"
    DEFAULAT_TIME = 180

    def self.run(argv)
      STDOUT.sync = true
      opts = {}
      opt = OptionParser.new(argv)
      opt.version = VERSION
      opt.banner = "Usage: #{opt.program_name} [-h|--help] args"
      opt.separator('')
      opt.separator('Options:')
      opt.on_head('-h', '--help', 'Show this message') do |v|
        puts opt.help
        exit
      end      
      opt.on('-v', '--verbose', 'Verbose message') {|v| opts[:v] = v}
      opt.on('-p PREFIX', '--prefix PREFIX', 'Capture file prefix.') {|v| opts[:p] = v}
      opt.on('-D DISPLAY', '--display DISPLAY', Integer, 'Capture from the display specified. -D 1 is main display, -D 2 secondary, etc.') {|v| opts[:d] = v}
      opt.on('-t TIME', '--time TIME', Integer, 'Recording time.') {|v| opts[:t] = v}
      opt.parse!(argv)
      cmd = Imageburst.new(opts)
      cmd.run
    end

    def initialize(opts)
      @opts = opts
    end

    def run
      # 撮影時間
      time = DEFAULAT_TIME
      if @opts[:t]
        time = @opts[:t]
      end

      # prefixの決定
      prefix = Time.now.strftime("%Y%m%d_%H%M%S")
      if @opts[:p]
        prefix = @opts[:p]
      end

      # ディスプレイの設定
      display = ''
      if @opts[:d]
        display = "-D#{@opts[:d]}"
      end

      # 現在時刻
      current = Time.now
      # 終了時間
      finish = current + time

      # 保存フォルダ(ベースフォルダの下に現在日付のフォルダを作成しその下に保存)
#      session = Time.now.strftime("%Y%m%d_%H%M%S")
      folder = File.expand_path(File.join(BASE_FOLDER, prefix))
      if FileTest.directory?(folder)
        puts "Output folder already exists: #{folder}"
        exit(1)
      end
      Dir.mkdir(folder)
      
      while current < finish
        current = Time.now
        name = current.strftime("%s_%6N.jpg")
        
        path = File.join(folder, name)
        cmd = "screencapture #{display} #{path}"
        puts cmd
        system(cmd)
      end
      
    end
  end
end
