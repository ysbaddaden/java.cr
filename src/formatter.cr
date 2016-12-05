require "./parser"

module JavaP
  class Formatter
    private getter parser : Parser

    def initialize(@parser)
      @forall = [] of String
    end

    def to_crystal(io)
      #io.puts "require \"java/jni\"\n\n"

      namespace = parser.class_name.split('.')
      class_name = namespace.pop

      if extends = parser.extends
        # TODO: relative require (instead of global)
        path = extends.split('.').map(&.underscore).join('/')
        path = ("../" * namespace.size) + path
        io.puts "require #{path.inspect}"
      end

      if idx = class_name.index('$')
        io.puts "require \"./#{class_name[0...idx].underscore}\""
      end

      namespace.each_with_index do |ns, i|
        io.puts "module #{to_class(ns)}"
        io.puts "include JNI\n\n" if i == 0
      end

      io.print "abstract " if parser.abstract?
      io.print "class #{to_class(class_name.gsub('$', "::"))}"
      if extends = parser.extends
        io.puts " < #{to_class(extends)}"
      else
        io.puts " < JNI::JObject"
      end

      io.puts <<-JCLASS
      def self.jclass
        @@jclass ||= JClass.new("#{parser.descriptor}")
      end\n\n
      JCLASS

      parser.fields.each do |f|
        format_field(f, io)
      end

      parser.methods.each do |m|
        format_method(m, io)
      end

      io.puts "end" # class

      namespace.each do |ns|
        io.puts "end"
      end
    end

    private def to_class(str)
      case str
      when "boolean", "byte", "char", "short", "int", "long", "float", "double"
        "J#{str.camelcase}"
      when "java.lang.String", "java.lang.CharSequence"
        "String"
      when .starts_with?('?')
        "W#{@forall.size}".tap { |type| @forall << type }
      else
        if str.ends_with?("...")
          "#{to_class(str[0...-3])}..."
        elsif str.ends_with?("[]")
          "Array(#{to_class(str[0...-2])})"
        elsif (idx = str.index('<')) && str.ends_with?('>')
          type = to_class(str[0...idx])
          generic = str[(idx + 1)...-1]
            .split(", ")
            .map { |t| to_class(t).as(String) }
            .join(", ")
          "#{type}(#{generic})"
        else
          str
            .gsub('$', '.')
            .split('.')
            .map(&.camelcase)
            .join("::")
        end
      end
    end

    private def format_field(f, io)
      if f.static?
        format_static_field(f, io)
      else
        format_field_getter(f, io)
        format_field_setter(f, io)
      end
      io.puts
    end

    private def format_field_getter(f, io)
      io.puts "def #{f.name}"
      io.puts "fid = jclass.field_id(#{f.name.inspect}, #{f.descriptor.inspect})"
      case method = f.jni_getter_method_name
      when "getObjectField"
        io.puts "obj = JNI.call(:#{method}, jclass.to_unsafe, fid)"
        if f.type == "String"
          io.puts "JNI.to_string(obj)"
        else
          io.puts "#{to_class(f.type.to_s)}.new(obj)"
        end
      else
        io.puts "JNI.call(:#{method}, jclass.to_unsafe, fid)"
      end
      io.puts "end"
    end

    private def format_field_setter(f, io)
      io.puts "def #{f.name}=(value : #{to_class(f.type.to_s)})"
      io.puts "JNI.call(:#{f.jni_setter_method_name}, jclass.to_unsafe, fid, value.to_unsafe)"
      io.puts "value"
      io.puts "end"
    end

    private def format_static_field(f, io)
      io.puts "#{f.name} = begin"
      io.puts "fid = jclass.static_field_id(#{f.name.inspect}, #{f.descriptor.inspect})"
      case f.jni_method_name
      when "callStaticObjectField"
        io.puts "obj = JNI.call(:#{f.jni_method_name}, jclass.to_unsafe, fid)"
        if f.type == "String"
          io.puts "JNI.to_string(obj)"
        else
          io.puts "#{to_class(f.type.to_s)}.new(obj)"
        end
      else
        io.puts "JNI.call(:#{f.jni_method_name}, jclass.to_unsafe, fid)"
      end
      io.puts "end"
    end

    private def format_field_body(f, io)
    end

    private def format_method(m, io)
      @forall.clear

      # definition
      args = m.args.map_with_index do |type, i|
        if m.variadic? && (i == m.args.size - 1)
          "*x#{i} : #{to_class(type)}"
        else
          "x#{i} : #{to_class(type)}"
        end
      end

      if m.abstract?
        _abstract = "abstract "
      end
      if m.static?
        static = "self."
      end

      #if type = m.forall
      #  forall = " forall #{type}"
      #end

      if m.visibility && m.visibility != "public"
        visibility = "#{m.visibility} "
      end

      if m.throws.any?
        io.puts "# NOTE: throws `#{m.throws.join("`, `")}`"
      end

      if parser.constructor?(m)
        io.print "#{_abstract}def self.new(#{args.join(", ")})"
      else
        name = m.name.gsub('$', '_')
        #if m.getter?
        #  io.print "#{_abstract}#{visibility}def #{static}#{name.sub("get_", "")}"
        #elsif m.setter?
        #  io.print "#{_abstract}#{visibility}def #{static}#{name.sub("set_", "")}=(#{args.join(", ")})"
        #else
          io.print "#{_abstract}#{visibility}def #{static}#{name}(#{args.join(", ")})"
        #end
      end

      if @forall.any?
        io.puts " forall #{@forall.join(", ")}"
        io.puts "# avoid crystal format error"
      else
        io.puts
      end

      # abstract methods don't have bodies
      return if m.abstract?

      # arguments as jvalue*
      args = format_args(m, io)

      # method handle

      # call jni method
      if parser.constructor?(m)
        io.puts "mid = jclass.method_id(\"<init>\", #{m.descriptor.inspect})"
        io.print "new JNI.call(:newObjectA, jclass.to_unsafe, mid"
        io.puts args ? ", #{args}.to_unsafe)" : ")"
      else
        io.puts "mid = jclass.method_id(#{m.java_name.inspect}, #{m.descriptor.inspect})"
        object = m.static? ? "jclass.to_unsafe" : "this"

        case m.jni_method_name
        when "callObjectMethodA", "callStaticObjectMethodA"
          io.print "obj = JNI.call(:#{m.jni_method_name}, #{object}.to_unsafe, mid"
          io.puts args ? ", #{args}.to_unsafe)" : ")"
          if m.type == "String"
            io.puts "JNI.to_string(obj)"
          else
            io.puts "#{to_class(m.type.to_s)}.new(obj)"
          end
        else
          io.print "JNI.call(:#{m.jni_method_name}, #{object}, mid"
          io.puts args ? ", #{args}.to_unsafe)" : ")"
        end
      end

      io.puts "end"
      io.puts
    end

    # TODO: NULL (?)
    private def format_args(m, io)
      return if m.args.empty?

      m.args.each_with_index do |arg, i|
        break if m.variadic? && (i == m.args.size - 1)
        format_arg(i, arg, io)
      end

      unless m.variadic?
        return "StaticArray[#{m.args.each_index.map { |i| "arg#{i}" }.join(", ")}]"
      end

      i = m.args.size - 1
      io.puts "args = Array(LibJNI::Jvalue).new"

      0.upto(i - 1) do |j|
        io.puts "args << arg#{j}"
      end

      io.puts "x#{i}.each do |arg|"
      format_arg(i, m.args.last, io)
      io.puts "args << arg#{i}"
      io.puts "end"

      "args"
    end

    private def format_arg(i, type, io)
      io.print "arg#{i} = LibJNI::JValue.new; "
      case to_class(type)
      when "boolean" then io.puts "arg#{i}.z = x#{i}"
      when "byte"    then io.puts "arg#{i}.b = x#{i}"
      when "char"    then io.puts "arg#{i}.c = x#{i}"
      when "short"   then io.puts "arg#{i}.s = x#{i}"
      when "int"     then io.puts "arg#{i}.i = x#{i}"
      when "long"    then io.puts "arg#{i}.j = x#{i}"
      when "fLoat"   then io.puts "arg#{i}.f = x#{i}"
      when "double"  then io.puts "arg#{i}.d = x#{i}"
      when "String"  then io.puts "arg#{i}.l = JNI.call(:newStringUTF, x#{i}.to_unsafe)"
      else                io.puts "arg#{i}.l = x#{i}"
      end
    end
  end
end
