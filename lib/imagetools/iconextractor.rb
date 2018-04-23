# coding: utf-8

require "imagetools/version"
require "optparse"
require "json"


module Imagetools
  class Iconextractor
    def self.run(argv)
      opts = {}
      opt = OptionParser.new(argv)
      opt.banner = "Usage: #{opt.program_name} [-h|--help] <app1 app2 app3 ...>"
      opt.version = VERSION
      opt.separator('')
      opt.separator("Options:")
      opt.on_head('-h', '--help', 'Show this message') do |v|
        puts opt.help
        exit
      end      
      opt.on('-v', '--verbose', 'Verbose message') {|v| opts[:v] = v}
      opt.on('-o OUTDIR', '--output=OUTDIR', 'Output dir') {|v| opts[:o] = v}
      opt.parse!(argv)
      
      app_files = get_app_files(argv)
      if app_files.size < 1
        puts opt.help
        exit
      end
      command = Iconextractor.new(opts)
      command.run(app_files)
    end

    def self.get_app_files(argv)
      app_files = []
      argv.each do |arg|
        if FileTest.directory?(arg) && arg =~ /\.app/
          app_path = File.expand_path(arg)
#          puts app_path
          app_files << app_path
        end
      end
      app_files
    end

    def initialize(opts)
      @opts = opts
    end

    def run(app_files)
      app_files.each do |app_path|
        icns_path = get_icns_path(app_path)
        icns_to_png(icns_path)
      end
    end

    private
    def get_icns_path(app_path)
      info_plist = File.join(app_path, 'Contents/Info.plist')
      #      puts info_plist
      json_str = `plutil -convert json #{info_plist} -o - `
      json_data = JSON.parse(json_str)
      icns_base = json_data["CFBundleIconFile"]

      icns_path = File.join(app_path, "Contents/Resources/#{icns_base}.icns")
      icns_path
      
#      str = File.read(info_plist)
#      data = JSON.parse(str)
#      p data["CFBundleTypeIconFile"]
    end

    def icns_to_png(icns_path)
      outdir = @opts[:o] || '.'

      icns_base = File.basename(icns_path)
      png_base = icns_base.sub(/\.icns$/, '.png')
      png_path = File.join(outdir, png_base)
      
      cmd = "sips -s format png #{icns_path} --out #{png_path}"
      puts cmd
      if !system(cmd)
        raise RuntimeError
      end
    end
  end
end
