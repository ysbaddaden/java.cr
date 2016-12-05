require "./parser"
require "./formatter"
require "compiler/crystal/formatter"
require "option_parser"

class JavaP::Generator
  struct Options
    property output
    property force
    property debug
    property follow
    property class_names
    property save

    def initialize
      @output = "bindings"
      @class_names = Set(String).new
      @follow = "basic"
      @force = false
      @debug = false
      @save = true
    end
  end

  property options : Options
  property dependencies
  property generated

  def initialize(@options)
    @dependencies = Array(String).new
    @generated = Array(String).new
  end

  def generate(class_name)
    if options.debug
      puts transform(class_name)
      exit
    end

    filename = class_name.gsub('$', '.').split('.').map(&.underscore).join('/')
    path = File.join(Dir.current, options.output, "#{filename}.cr")

    if File.exists?(path) && !options.force
      print "Exists".colorize(:green)
      puts " #{class_name} => #{path}"
    else
      print "Generating".colorize(:yellow)
      puts " #{class_name} => #{path}"
      code = transform(class_name)
      dirname = File.dirname(path)
      Dir.mkdir_p(dirname) unless Dir.exists?(dirname)

      if options.save
        File.open(path, "w") { |file| file << code }
      end
    end
  end

  def transform(class_name)
    parser = JavaP::Parser.parse(javap(class_name))

    io = IO::Memory.new
    formatter = JavaP::Formatter.new(parser)

    formatter.to_crystal(io)
    code = io.rewind.to_s

    begin
      code = Crystal::Formatter.format(code)
    rescue ex : Crystal::SyntaxException
      puts "=====================> DEBUG <====================="
      puts ex.message
      puts code
      exit -1
    end

    generated << parser.class_name

    if options.follow == "basic"
      parser.extends.each do |type|
        add_dependency(type)
      end
      parser.implements.each do |type|
        add_dependency(type)
      end
    end

    if options.follow == "full"
      formatter.all_types.each do |type|
        add_dependency(type)
      end
    end

    code
  end

  private def add_dependency(type)
    if idx = type.index('<')
      add_dependency(type[0...idx])
      add_dependency(type[(idx + 1)..-1])
    elsif idx = type.index('>')
      x = type[0...idx]
      add_dependency(x) unless x.empty?
    elsif !generated.includes?(type) && !dependencies.includes?(type) && type.includes?('.')
      dependencies << type
    end
  end

  def javap(class_name)
    cache("#{class_name}.java") do
      stdout, stderr = IO::Memory.new, IO::Memory.new
      status = Process.run("javap", {"-s", class_name}, output: stdout, error: stderr)
      raise stderr.to_s unless status.success?
      stdout.to_s
    end
  end

  private def cache(filename)
    path = File.join("tmp", "cache", filename)
    if File.exists?(path)
      File.read(path)
    else
      yield.tap do |contents|
        parent = File.dirname(path)
        Dir.mkdir_p(parent) unless Dir.exists?(parent)
        File.write(path, contents)
      end
    end
  end
end

options = JavaP::Generator::Options.new

OptionParser.parse! do |opts|
  opts.on("-h", "--help", "Show this help") do
    puts "Usage:"
    puts "  #{File.basename(PROGRAM_NAME)} [options] class_name class_name ..."
    puts "  #{File.basename(PROGRAM_NAME)} [options] < class_names.txt"
    puts opts
    exit
  end

  opts.on("-o FOLDER", "--output FOLDER", "Destination directory to save the bindings") do |folder|
    options.output = folder
  end

  opts.on("--follow=VALUE", "Follow dependencies and generate bindings for them.  (none: don't follow, basic: follow extends/implements, full: follow all types)") do |value|
    options.follow = value
  end

  opts.on("-f", "--force", "Always generate bindings") do
    options.force = true
  end

  opts.on("-d", "--debug", "Outputs a single class to STDOUT") do
    options.debug = true
  end

  opts.on("--no-save", "Don't save generated bindings on disk") do
    options.save = false
  end

  opts.unknown_args do |args, _|
    args.each { |arg| options.class_names << arg }
  end
end

generator = JavaP::Generator.new(options)

if options.class_names.any?
  options.class_names.each do |class_name|
    generator.generate(class_name.strip)
  end
else
  STDIN.each_line do |class_name|
    generator.generate(class_name.strip)
  end
end

unless options.follow == "none"
  while type = generator.dependencies.shift?
    generator.generate(type)
  end
end
