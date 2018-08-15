# coding: utf-8

require 'imagetools/version'
require "optparse"
require "fileutils"

module Imagetools
  class Iconcreator
    
    IOS_ICON_INFOS = [
      ##### iPhone icons #####
      ["20x20", "iphone", "2x"], # iPhone Notification iOS 7-11
      ["20x20", "iphone", "3x"], #
      ["29x29", "iphone", "2x"], # iPhone Spotlight iOS 5,6/Settings iOS 5-11
      ["29x29", "iphone", "3x"], #
      ["40x40", "iphone", "2x"], # iPhone Spotlight iOS 7-11
      ["40x40", "iphone", "3x"], #
      ["60x60", "iphone", "2x"], # iPhone App iOS 7-11
      ["60x60", "iphone", "3x"], #
      ##### iPad icons #####
      ["20x20", "ipad", "1x"], # iPad Notification iOS 7-11
      ["20x20", "ipad", "2x"], #
      ["29x29", "ipad", "1x"], # iPad Settings iOS 6-11
      ["29x29", "ipad", "2x"], #
      ["40x40", "ipad", "1x"], # iPad Spotlight iOS 7-11
      ["40x40", "ipad", "2x"], #
      ["76x76", "ipad", "1x"], # iPad App iOS 7-11
      ["76x76", "ipad", "2x"], #
      ["83.5x83.5", "ipad", "2x"], # iPad Pro App iOS 9-11
      ##### App Store #####
      ["1024x1024", "ios-marketing", "1x"], # App Store iOS
    ]

    MACOS_ICON_INFOS = [
      ##### mac #####
      ["16x16", "mac", "1x"], # Mac 16pt
      ["16x16", "mac", "2x"], # 
      ["32x32", "mac", "1x"], # Mac 32pt
      ["32x32", "mac", "2x"], # 
      ["128x128", "mac", "1x"], # Mac 128pt
      ["128x128", "mac", "2x"], #
      ["256x256", "mac", "1x"], # Mac 256pt
      ["256x256", "mac", "2x"], #   
      ["512x512", "mac", "1x"], # Mac 512pt
      ["512x512", "mac", "2x"], #             
    ]
  
    def self.run(argv)
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
      types = ['ios', 'mac']
      opt.on('-t', '--type', types, types.join("|") + "(default ios)") {|v| opts[:t] = v }
      opt.on('-i INPUTFILE', '--input=INPUTFILE', 'Original icon file(1024x1024 recommended') {|v| opts[:i] = v} 
      opt.on('-o OUTDIR', '--output=OUTDIR', 'Output dir(<PROJECT>/Assets.xcassets or any folder)') {|v| opts[:o] = v}
      opt.parse!(argv)
      opts[:i] ||= 'icon.png'
      opts[:t] ||= types[0]
      if !FileTest.file?(opts[:i])
        puts opt.help
        exit
      end
      opts[:o] ||= "./out"            
      command = Iconcreator.new(opts)
      command.run
    end

    def self.realsize(point, scale)
      unless point=~ /^([0-9.]+)x/
        raise "invalid point #{point}"
      end
      point_value = $1.to_f
      unless scale =~ /^(\d+)x/
        raise "invalid scale #{point}"  
      end
      scale_value = $1.to_i
      (point_value * scale_value).to_i
    end

    def self.filename(point, scale)
      "Icon-#{point}@#{scale}.png"
    end

    def initialize(opts)
      @opts = opts
    end

    def run
      puts "Create #{@opts[:t]} app icons"

      outdir = @opts[:o]
      inputfile = @opts[:i]      
      unless FileTest.directory?(outdir)
        FileUtils.mkdir(outdir)
      end

      appicondir = outdir + '/AppIcon.appiconset'
      if FileTest.directory?(appicondir)
        FileUtils.rm_rf(appicondir)
        FileUtils.mkdir(appicondir)        
      else
        FileUtils.mkdir(appicondir)
      end

      icon_infos = @opts[:t] == 'ios' ? IOS_ICON_INFOS : MACOS_ICON_INFOS

      filenames = []
      icon_infos.each_with_index do |icon_info, index|
        point, idiom, scale = icon_info
#        puts "point=#{point} idiom=#{idiom} scale=#{scale}"
        
        realsize = self.class.realsize(point, scale)
        filename = self.class.filename(point, scale)
        filenames[index] = filename
        path = appicondir + "/" + filename
        cmd = "sips -Z #{realsize} #{inputfile} --out #{path} > /dev/null 2>&1"
        puts cmd
        system(cmd)
      end

      str = ""
      str << "{\n"
      str << "  \"images\" : [\n"
      icon_infos.each_with_index do |icon_info, index|
        point, idiom, scale = icon_info
        filename = filenames[index]
        str << "    {\n"
        str << "      \"size\": \"#{point}\",\n"
        str << "      \"idiom\": \"#{idiom}\",\n"
        str << "      \"filename\": \"#{filename}\",\n"
        str << "      \"scale\": \"#{scale}\"\n"
        if index < icon_infos.size - 1
          str << "    },\n"
        else
          str << "    }\n"          
        end
      end        
      str << "  ],\n"        
      str << "  \"info\" : {\n"
      str << "    \"version\" : 1,\n"
      str << "    \"author\" : \"xcode\"\n"
      str << "  }\n"
      str << "}\n"        

      contents_json = appicondir + '/Contents.json'
      puts "Create #{contents_json}"
      open(contents_json, 'w') do |f|
        f.print(str)
      end
    end
  end
end
