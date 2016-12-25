require "./parser"
require "./formatter"
require "compiler/crystal/formatter"
require "option_parser"

module JavaP
  class Generator
    struct Options
      property output
      property force
      property debug
      property follow
      property types
      property save
      property cache
      property quiet
      property verbose

      def initialize
        @output = "bindings"
        @types = Set(String).new
        @follow = /^java\./
        @force = false
        @debug = false
        @save = true
        @cache = true
        @quiet = false
        @verbose = false
      end
    end

    property options : Options
    property types
    property dependencies

    def initialize(@options)
      @types = {} of String => Parser
      @dependencies = [] of String
    end

    def load(type)
      @types[type] ||= begin
        if options.verbose
          print "Loading".colorize(:dark_gray)
          puts " #{type}"
        end
        Parser.parse(javap(type)).tap do |parser|
          parser.all_types.each { |type| add_dependency(type) }
        end
      end
    end

    def generate(type)
      filename = type.gsub('$', '_').split('.').map(&.underscore).join('/')
      path = File.join(Dir.current, options.output, "#{filename}.cr")

      if File.exists?(path) && !options.force
        if options.verbose
          print "Exists".colorize(:green)
          puts " #{type} => #{path}"
        end
      else
        unless options.quiet
          print "Generating".colorize(:yellow)
          puts " #{type} => #{path}"
        end
        code = transform(type)
        dirname = File.dirname(path)
        Dir.mkdir_p(dirname) unless Dir.exists?(dirname)

        if options.save
          File.open(path, "w") { |file| file << code }
        end
      end
    end

    def transform(type)
      io = IO::Memory.new
      parser = load(type)

      formatter = JavaP::Formatter.new(parser, types)
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

    private def add_dependency(type)
      if idx = type.index('<')
        add_dependency(type[0...idx])
        add_dependency(type[(idx + 1)..-1])
      elsif idx = type.index('>')
        x = type[0...idx]
        add_dependency(x) unless x.empty?
      elsif !types.has_key?(type) && !dependencies.includes?(type) && type.includes?('.') && type =~ options.follow
        dependencies << type
        if idx = type.index('$')
          add_dependency(type[0...idx])
        end
      end
    end

    def javap(type)
      cache("#{type}.java") do
        stdout, stderr = IO::Memory.new, IO::Memory.new
        status = Process.run("javap", {"-s", type}, output: stdout, error: stderr)
        raise stderr.to_s unless status.success?
        stdout.to_s
      end
    end

    private def cache(filename)
      unless options.cache
        return yield
      end

      path = File.join("tmp", "cache", filename)
      if File.exists?(path)
        return File.read(path)
      end

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
    puts "  #{File.basename(PROGRAM_NAME)} [options] type type ..."
    puts "  #{File.basename(PROGRAM_NAME)} [options] < types.txt"
    puts opts
    exit
  end

  opts.on("-o FOLDER", "--output FOLDER", "Destination directory to save the bindings") do |folder|
    options.output = folder
  end

  opts.on("--follow=PATTERN", "Follow types matching PATTERN only (default: 'java.'") do |pattern|
    options.follow = Regex.new(pattern)
  end

  opts.on("--no-follow", "Don't follow types") do
    options.follow = Regex.new("THIS JAVA TYPE CAN'T POSSIBLY EXIST")
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

  opts.on("--quiet", "Don't output anything (but errors)") do
    options.quiet = true
    options.verbose = false
  end

  opts.on("--verbose", "Increase output verbosity (what is loaded, generated, ...)") do
    options.quiet = false
    options.verbose = true
  end

  opts.unknown_args do |args, _|
    args.each { |arg| options.types << arg }
  end
end

generator = JavaP::Generator.new(options)

# debug: print the first class to STDOUT then exit
if options.debug
  type = (options.types.first? || STDIN.read_line).strip
  puts generator.transform(type)
  exit
end

# parse java types
if options.types.any?
  options.types.each do |type|
    generator.load(type.strip)
  end
else
  STDIN.each_line do |type|
    generator.load(type.strip)
  end
end

# load dependent java types
while type = generator.dependencies.shift?
  generator.load(type)
end

# generate bindings
generator.types.each_key do |type|
  generator.generate(type)
end
