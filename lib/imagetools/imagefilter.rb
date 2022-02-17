# coding: utf-8

require 'imagetools/version'
require 'fileutils'
require 'optparse'
require 'yaml'

module Imagetools
  class Config
    FILENAME_SEARCH = 's (\d+)-(\d+)-(\d+) (\d+)\.(\d+)\.(\d+)'
    FILENAME_REPLACE = 's_\1\2\3_\4\5\6'
    
    def initialize(yaml)
      @yaml = yaml
      @filename_search1 = config_value("filename", "search1", false) || FILENAME_SEARCH
      @filename_replace1 = config_value("filename", "replace1", false) || FILENAME_REPLACE
      @filename_search2 = config_value("filename", "search2", false)
      @filename_replace2 = config_value("filename", "replace2", false)
      @filename_search3 = config_value("filename", "search3", false)
      @filename_replace3 = config_value("filename", "replace3", false) 
    end

    attr_reader :filename_search1, :filename_replace1,
                :filename_search2, :filename_replace2,
                :filename_search3, :filename_replace3 

    def filename_patterns
      [
        [@filename_search1, @filename_replace1],
        [@filename_search2, @filename_replace2],
        [@filename_search3, @filename_replace3],  
      ]
    end
    
    private
    def config_value(section, key, require)
      return nil unless @yaml
      value = @yaml[section][key]
      if require && (value.nil? || value.empty?)
        raise RuntimeError, "#{section}:#{key}: is empty"
      end
      value
    end    
  end
  
  class Imagefilter
    OTHER_JPG_SEARCH = /\.(large|huge|jpg_large|JPG)$/i
    OTHER_JPG_REPLACE = '.jpg'
    
    CONVERT_CMD = "convert"
    DWEBP_CMD = "dwebp"
    #    RESIZE_CMD = "mogrify -resize 1280x\\> "
    RESIZE_CMD = "mogrify -background white -resize 1280x\\> "    
    ROTATE_CMD = "exiftran -ai "
    COMPRESS_CMD = "jpegoptim --strip-all --max=90 "
    EXTERNAL_CMDS = [RESIZE_CMD, ROTATE_CMD, COMPRESS_CMD]

    WEBP_SEARCH = /(.+)\.webp/i
    WEBP_REPLACE = '\1.png'
    
    PNG_SEARCH = /(.+)\.png/i
    PNG_REPLACE = '\1.jpg'
    JPG_SEARCH = /(.+)\.jpe?g/i
    HEIC_SEARCH = /(.+)\.heic/i
    HEIC_REPLACE = '\1.jpg'
    
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
    ROTATE_CMD:   #{ROTATE_CMD} 
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
      opt.on('-c', '--config', 'Config file'){|v| opts[:c] = v }
      opt.parse!(argv)

      config_file = opts[:c] || "~/.imagefilterrc"
      config_file = File.expand_path(config_file)
      yaml = nil
      if FileTest.file?(config_file)
        yaml = YAML.load_file(config_file)
      end
      config = Config.new(yaml)
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
        command = Imagefilter.new(opts, config)
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

    def self.replace_image_filename(filename, patterns)
      filename = filename.dup      
      patterns.each do |search, replace|
        if search && replace
          reg = Regexp.new(search, Regexp::IGNORECASE)
          filename = filename.sub(reg, replace)
        end
      end
      filename.sub(OTHER_JPG_SEARCH, OTHER_JPG_REPLACE)
    end

    def self.replace_webp2png(filename)
      filename.sub(WEBP_SEARCH, WEBP_REPLACE)
    end
    
    def self.replace_png2jpg(filename)
      filename.sub(PNG_SEARCH, PNG_REPLACE)
    end

    def self.replace_heic2jpg(filename)
      filename.sub(HEIC_SEARCH, HEIC_REPLACE)
    end

    def self.match_exclude_image?(filename)
      filename =~ EXCLUDE_PAT
    end

    def self.selftest
      EXTERNAL_CMDS.each do |cmd|
        args = cmd.split
        cmd_name = args[0]
        unless cmd_exists?(cmd_name)
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
    
    def initialize(opts, config)
      @opts = opts
      @config = config
    end

    def run(filepath)
      if exclude_image?(filepath)
        return
      end
      filepath = rename_image(filepath)
      filepath = webp2png(filepath)
      filepath = png2jpg(filepath)
      filepath = heic2jpg(filepath)      
      filepath = resize_jpg(filepath)
      filepath = rotate_jpg(filepath)
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
    
    def rename_image(filepath)
      fromname = File.basename(filepath)
      toname = self.class.replace_image_filename(fromname, @config.filename_patterns)
      return filepath if fromname == toname

      dir = File.dirname(filepath)
      topath = File.join(dir, toname)
      puts "rename: #{filepath} => #{topath}"
      #      FileUtils.mv(filepath, topath, :force => true) unless @opts[:n]
      # aaa.JPG => aaa.jpgを成功させるためにFIleUtils.mv(same fileエラーがでる)ではなくmvを使う
      cmd = "mv \"#{filepath}\" \"#{topath}\""
      system(cmd)
      return topath
    end

    def webp2png(filepath)
      fromname = File.basename(filepath)
      toname = self.class.replace_webp2png(fromname)
      return filepath if fromname == toname

      dir = File.dirname(filepath)
      topath = File.join(dir, toname)
      puts "convert: #{filepath} => #{topath}"
      # dwebp ~/Desktop/1.webp -o ~/Desktop/1.jpg      
      cmd = "#{DWEBP_CMD} \"#{filepath}\" -o \"#{topath}\""
      if system(cmd)
        FileUtils.rm(filepath)
      end
      return topath
    end
    
    def png2jpg(filepath)
      fromname = File.basename(filepath)
      toname = self.class.replace_png2jpg(fromname)
      return filepath if fromname == toname

      dir = File.dirname(filepath)
      topath = File.join(dir, toname)
      puts "convert: #{filepath} => #{topath}"
      # convert test.png -background "#ffff00" -flatten test.jpg
      cmd = "#{CONVERT_CMD} \"#{filepath}\" -background \"#ffffff\" -flatten \"#{topath}\""
      if system(cmd)
        FileUtils.rm(filepath)
      end
      return topath
    end

    def heic2jpg(filepath)
      fromname = File.basename(filepath)
      toname = self.class.replace_heic2jpg(fromname)
#      puts "heic2jpg #{fromname}=>#{toname}"      
      return filepath if fromname == toname

      dir = File.dirname(filepath)
      topath = File.join(dir, toname)
      puts "convert: #{filepath} => #{topath}"
      # convert ~/Desktop/test.heic -o ~/Desktop/test.jpg
      cmd = "#{CONVERT_CMD} \"#{filepath}\" \"#{topath}\""
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

    def rotate_jpg(filepath)
      fromname = File.basename(filepath)
      unless fromname =~ JPG_SEARCH
        return filepath 
      end
      puts "rotate: #{filepath}"
      cmd = "#{ROTATE_CMD} \"#{filepath}\""
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
