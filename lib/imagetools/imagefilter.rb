# coding: utf-8

require 'imagetools/version'
require 'fileutils'
require 'optparse'

module Imagetools
  class Imagefilter

    SCREENSHOT_SEARCH = /s (\d+)-(\d+)-(\d+) (\d+)\.(\d+)\.(\d+).jpg/
    SCREENSHOT_REPLACE = 's_\1\2\3_\4\5\6.jpg'
    RESIZE_CMD = "mogrify -resize 1280x\\> "
    COMPRESS_CMD = "jpegoptim --strip-all --max=90 "
    EXTERNAL_CMDS = [RESIZE_CMD, COMPRESS_CMD]
    
    PNG_SEARCH = /(.+)\.png/i
    PNG_REPLACE = '\1.jpg'
    JPG_SEARCH = /(.+)\.jpe?g/i
    EXCLUDE_PAT = /^_/ # 先頭が"_"の場合は除外
    
    def self.run(argv)
      STDOUT.sync = true
      opts = {}
      opt = OptionParser.new(argv)
      opt.banner = "Usage: #{opt.program_name} [-h|--help] <args>"
      opt.version = VERSION
      opt.separator('')
      opt.separator('Parameters:')
      param =<<EOM
    RESIZE_CMD:   #{RESIZE_CMD}
    COMPRESS_CMD: #{COMPRESS_CMD}
EOM
      opt.separator(param)
      opt.separator('')      
      opt.separator("Options:")
      opt.on_head('-h', '--help', 'Show this message') do |v|
        puts opt.help
        exit
      end
#      # 冗長メッセージ
      opt.on('-v', '--verbose', 'Verbose message') {|v| opts[:v] = v}
      opt.on('-n', '--dry-run', 'Message only') {|v| opts[:n] = v}
      opt.on('-t', '--self-test', 'Run Self Test') {|v| opts[:t] = v}
      opt.parse!(argv)
      if opts[:t]
        ret = selftest
        exit(ret)
      end
      filepaths = self.filter_files(argv)
      if filepaths.empty?
        puts opt.help
        exit
      end
      filepaths.each do |filepath|
        command = Imagefilter.new(opts)
        command.run(filepath)
      end
    end

    def self.filter_files(argv)
      filepaths = []
      argv.each do |arg|
        if FileTest.file?(arg) 
          path = File.expand_path(arg)
          filepaths << path
        end
      end
      filepaths
    end

    def self.replace_screenshot_filename(filename)
      filename.sub!(SCREENSHOT_SEARCH, SCREENSHOT_REPLACE)
    end

    def self.replace_png2jpg(filename)
      filename.sub!(PNG_SEARCH, PNG_REPLACE)
    end

    def self.match_exclude_image?(filename)
      filename =~ EXCLUDE_PAT
    end

    def self.selftest
      EXTERNAL_CMDS.each do |cmd|
        args = cmd.split
        cmd_name = args[0]
        unless cmd_exists?(cmd)
          puts "No command:  #{cmd_name}"
          return 127
        end
      end
      return 0
    end

    def self.cmd_exists?(cmd)
      # whichはコマンドが存在する場合のみ標準出力にパスを出力する
      `which #{cmd}` != ""
    end
    
    def initialize(opts)
      @opts = opts
    end

    def run(filepath)
      if exclude_image?(filepath)
        return
      end
      filepath = rename_screenshot(filepath)
      filepath = png2jpg(filepath)
      filepath = resize_jpg(filepath)
      filepath = compress_jpg(filepath)
      filepath
    end

    private
    def exclude_image?(filepath)
      fromname = File.basename(filepath)
      if self.class.match_exclude_image?(fromname)
        puts "exclude #{filepath}"
        return true
      end
      false
    end
    
    def rename_screenshot(filepath)
      fromname = File.basename(filepath)
      toname = self.class.replace_screenshot_filename(fromname)
      return filepath if toname.nil?

      dir = File.dirname(filepath)
      topath = File.join(dir, toname)
      puts "rename: #{filepath} => #{topath}"
      FileUtils.mv(filepath, topath) unless @opts[:n]
      return topath
    end

    def png2jpg(filepath)
      fromname = File.basename(filepath)
      toname = self.class.replace_png2jpg(fromname)
      return filepath if toname.nil?

      dir = File.dirname(filepath)
      topath = File.join(dir, toname)
      puts "convert: #{filepath} => #{topath}"
      # convert test.png -background "#ffff00" -flatten test.jpg
      cmd = "convert \"#{filepath}\" -background \"#ffffff\" -flatten \"#{topath}\""
      if system(cmd)
        FileUtils.rm(filepath)
      end
      return topath
    end

    def resize_jpg(filepath)
      fromname = File.basename(filepath)
      unless fromname =~ JPG_SEARCH
        return filepath 
      end
      puts "resize: #{filepath}"
      cmd = "#{RESIZE_CMD} \"#{filepath}\""
      system(cmd)
      return filepath
    end
    
    def compress_jpg(filepath)
      fromname = File.basename(filepath)
      unless fromname =~ JPG_SEARCH
        return filepath 
      end
      puts "compress: #{filepath}"
      cmd = "#{COMPRESS_CMD} \"#{filepath}\""
      system(cmd)
      return filepath
    end
  end
end
