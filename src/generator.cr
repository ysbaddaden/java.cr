require "./parser"
require "./formatter"
require "compiler/crystal/formatter"
require "option_parser"

def javap(class_name)
  stdout, stderr = IO::Memory.new, IO::Memory.new
  status = Process.run("javap", {"-s", class_name}, output: stdout, error: stderr)
  raise stderr.to_s unless status.success?
  stdout.to_s
end

def generate(class_name)
  parser = JavaP::Parser.parse(javap(class_name))
  return if parser.interface?

  io = IO::Memory.new
  formatter = JavaP::Formatter.new(parser)

  formatter.to_crystal(io)
  code = io.rewind.to_s

  begin
    Crystal::Formatter.format(code)
  rescue ex : Crystal::SyntaxException
    puts "=====================> DEBUG <====================="
    puts ex.message
    puts code
    exit -1
  end
end

struct Options
  property output
  property force

  def initialize
    @output = "bindings"
    @force = false
  end
end

options = Options.new

OptionParser.parse! do |opts|
  opts.on("-h", "--help", "Show this help") do
    puts "Usage:"
    puts "  #{File.basename(PROGRAM_NAME)} [options] class_name"
    puts "  #{File.basename(PROGRAM_NAME)} [options] < class_names.txt"
    puts opts
    exit
  end
  opts.on("-o FOLDER", "--output FOLDER", "Destination directory to save the bindings") do |folder|
    options.output = folder
  end
  opts.on("-f", "--force", "Alaways generate the Java bindings") do
    options.force = true
  end
end

if class_name = ARGV[0]?
  puts generate(class_name)
else
  STDIN.each_line do |class_name|
    class_name = class_name.strip
    path = File.join(Dir.current, options.output, class_name.split('.').map(&.underscore).join('/') + ".cr")

    if File.exists?(path) && !options.force
      print "Exists".colorize(:green)
      puts " #{class_name} => #{path}"
    else
      if code = generate(class_name)
        print "Creates".colorize(:yellow)
        puts " #{class_name} => #{path}"
        dirname = File.dirname(path)
        Dir.mkdir_p(dirname) unless Dir.exists?(dirname)
        File.open(path, "w") { |file| file << code }
      else
        print "Skips".colorize(:dark_gray)
        puts " interface #{class_name}"
      end
    end
  end
end
