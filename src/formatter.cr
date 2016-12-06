require "./parser"

module JavaP
  class Formatter
    private getter parser : Parser
    getter all_types

    def initialize(@parser)
      @forall = [] of String
      @all_types = Set(String).new
    end

    def to_crystal(io)
      #io.puts "require \"java/jni\"\n\n"

      namespace = parser.class_name.split('.')
      class_name = namespace.pop

      # hard requirements (namespace, extends, implements)

      parser.extends.each do |type|
        path = type.split('.').map(&.underscore).join('/')
        path = ("../" * namespace.size) + path.gsub('$', '_')
        io.puts "require #{path.inspect}"
      end

      parser.implements.each do |type|
        path = type.split('.').map(&.underscore).join('/')
        path = ("../" * namespace.size) + path.gsub('$', '_')
        io.puts "require #{path.inspect}"
      end

      if idx = class_name.index('$')
        io.puts "require \"./#{class_name[0...idx].underscore}\""
      end

      # class definition

      namespace.each_with_index do |ns, i|
        io.puts "module #{to_type(ns)}"
        io.puts "include JNI\n\n" if i == 0
      end

      # java classes and interfaces both become Crystal classes
      io.print "class #{to_type(class_name)}"
      if type = parser.extends.first?
        io.puts " < #{to_type(type, exact: true)}"
      else
        io.puts " < JNI::JObject"
      end

      # FIXME: A Java class may extend many classes, but Crytal can't extend
      #        multiple types, only inherit from a single class.
      #
      #        Maybe we should load/parse dependent classes/interfaces then
      #        generate bindings, knowing which type is an interface and which
      #        is a class, thus adding type restrictions in method arguments
      #        accordingly.
      #
      #        Java interfaces would become modules, and be included into a
      #        specific Module::Name::Interface class that would be instanciated
      #        for cases where an interface is returned.
      #
      #        For now interfaces become a class, and generated methods don't
      #        have any type restriction for objects, except for the generic
      #        JNI::JObject.

      # add following extends types, so actual classes are accepted for
      # interface restricted method arguments
      if parser.extends.size > 1
        parser.extends[1..-1].each do |type|
          io.puts "# extend #{to_type(type, exact: true)}"
        end
      end

      # extend implement types, so actual classes are accepted for
      # interface restricted method arguments
      parser.implements.each do |type|
        io.puts "# extend #{to_type(type, exact: true)}"
      end
      io.puts

      unless parser.interface?
        io.puts <<-JCLASS
        def self.jclass
          @@jclass ||= JClass.new("#{parser.descriptor}")
        end\n\n
        JCLASS
      end

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

    private def to_arg_type(str)
      if str == "boolean"
        "Bool"
      else
        name = to_type(str)
        # TODO: restrict jobject argument type (requires to deal with interfaces, see above)
        #name.includes?("::") ? "#{name}?" : name
        name.includes?("::") ? "JNI::JObject?" : name
      end
    end

    private def to_type(str, exact = false)
      case str
      when "boolean", "byte", "char", "short", "int", "long", "float", "double"
        # primitive
        "J#{str.camelcase}"
      when "java.lang.String", "java.lang.CharSequence"
        # FIXME: maybe the Crystal String class should extend `java.lang.CharSequence` instead?
        #        that would be accepted in arguments, and return types should
        #        assume the `java.lang.CharSequence` to be a `String`?
        exact ? to_crystal_type(str) : "String"
      when .starts_with?('?')
        "W#{@forall.size}".tap { |type| @forall << type }
      else
        if str.ends_with?("...")
          # variadic (last argument)
          "#{to_type(str[0...-3])}..."
        elsif str.ends_with?("[]")
          # array
          "Array(#{to_type(str[0...-2])})"
        elsif (idx = str.index('<')) && str.ends_with?('>')
          # generic
          type = to_type(str[0...idx])
          generic = str[(idx + 1)...-1]
            .split(", ")
            .map { |t| to_type(t).as(String) }
            .join(", ")
          "#{type}(#{generic})"
        else
          # namespace
          add_type(str)
          to_crystal_type(str)
        end
      end
    end

    private def to_crystal_type(str)
      str
        .split('.')
        .map(&.camelcase)
        .join("::")
        .gsub('$', '_')
    end

    private def add_type(str)
      if str.includes?('.') && str != parser.class_name
        @all_types << str
      end
    end

    private def format_field(f, io)
      if f.static?
        format_static_field(f, io)
      else
        #format_field_getter(f, io)
        #format_field_setter(f, io)
      end
      io.puts
    end

    #private def format_field_getter(f, io)
    #  io.puts "def #{f.name}"
    #  io.puts "fid = jclass.field_id(#{f.name.inspect}, #{f.descriptor.inspect})"
    #  case method = f.jni_getter_method_name
    #  when "getObjectField"
    #    io.puts "obj = JNI.call(:#{method}, jclass.to_unsafe, fid)"
    #    if f.type == "String"
    #      io.puts "JNI.to_string(obj)"
    #    else
    #      io.puts "#{to_type(f.type.to_s)}.new(obj)"
    #    end
    #  else
    #    io.puts "JNI.call(:#{method}, jclass.to_unsafe, fid)"
    #  end
    #  io.puts "end"
    #end

    #private def format_field_setter(f, io)
    #  io.puts "def #{f.name}=(value : #{to_type(f.type.to_s)})"
    #  io.puts "JNI.call(:#{f.jni_setter_method_name}, jclass.to_unsafe, fid, value.to_unsafe)"
    #  io.puts "value"
    #  io.puts "end"
    #end

    private def format_static_field(f, io)
      io.puts "#{to_constant(f.name)} = begin"
      io.puts "fid = jclass.static_field_id(#{f.name.inspect}, #{f.descriptor.inspect})"
      io.puts "ret = JNI.call(:#{f.jni_method_name}, jclass.to_unsafe, fid)"
      wrap_return_type(f, "ret", io)
      io.puts "end"
    end

    private def to_constant(str)
      str = str.gsub('$', "")
      if str.upcase == str
        str
      else
        str.underscore.camelcase
      end
    end

    private def format_method(m, io)
      @forall.clear

      # method definition

      args = m.args.map_with_index do |type, i|
        if m.variadic? && (i == m.args.size - 1)
          "*x#{i} : #{to_arg_type(type)}"
        else
          "x#{i} : #{to_arg_type(type)}"
        end
      end

      if m.static?
        static = "self."
      end

      #if type = m.forall
      #  forall = " forall #{type}"
      #end

      m.args.each_with_index do |arg, i|
        type = to_type(arg)
        io.puts "# NOTE: *x#{i}* : `#{type}` | Nil" if type.includes?("::")
      end

      if m.throws.any?
        io.puts "# NOTE: throws `#{m.throws.join("`, `")}`"
      end

      if parser.constructor?(m)
        #io.print "abstract " if m.abstract?
        io.print "def self.new(#{args.join(", ")})"
      else
        name = m.name.gsub('$', '_')
        #if m.abstract?
        #  io.print "abstract "
        #else
          if m.visibility && m.visibility != "public"
            io.print m.visibility
            io.print ' '
          end
        #end
        #if m.getter?
        #  io.print "def #{static}#{name.sub("get_", "")}"
        #elsif m.setter?
        #  io.print "def #{static}#{name.sub("set_", "")}=(#{args.join(", ")})"
        #else
          io.print "def #{static}#{name}(#{args.join(", ")})"
        #end
      end

      if @forall.any?
        io.puts " forall #{@forall.join(", ")}"
        io.puts "# avoid crystal format error"
      else
        io.puts
      end

      # abstract methods don't have bodies
      #return if m.abstract?

      # arguments as jvalue*
      args = format_args(m, io)

      # method handle

      # call jni method
      if parser.constructor?(m)
        io.puts "mid = jclass.method_id(\"<init>\", #{m.descriptor.inspect})"
        io.puts "new JNI.call(:newObjectA, jclass.to_unsafe, mid, #{args})"
      else
        io.puts "mid = jclass.method_id(#{m.java_name.inspect}, #{m.descriptor.inspect})"
        object = m.static? ? "jclass.to_unsafe" : "this"
        io.puts "ret = JNI.call(:#{m.jni_method_name}, #{object}, mid, #{args})"
        wrap_return_type(m, "ret", io)
      end

      io.puts "end"
      io.puts
    end

    private def wrap_return_type(x, ret, io)
      case x.jni_method_name
      when .includes?("Object")
        if x.type == "String"
          io.puts "JNI.to_string(#{ret})"
        else
          io.puts "#{to_type(x.type.to_s)}.new(#{ret})"
        end
      when .includes?("Boolean")
        io.puts "#{ret} == TRUE"
      else
        io.puts ret
      end
    end

    private def format_args(m, io)
      if m.args.empty?
        # no arguments: pass a null pointer
        return "Pointer(LibJNI::JValue).null"
      end

      m.args.each_with_index do |arg, i|
        break if m.variadic? && (i == m.args.size - 1)
        format_arg(i, arg, io)
      end

      if m.variadic?
        i = m.args.size - 1
        io.puts "args = Array(LibJNI::Jvalue).new"

        0.upto(i - 1) do |j|
          io.puts "args << arg#{j}"
        end

        io.puts "x#{i}.each do |arg|"
        format_arg(i, m.args.last, io)
        io.puts "args << arg#{i}"
        io.puts "end"

        "args.to_unsafe"
      else
        "StaticArray[#{m.args.each_index.map { |i| "arg#{i}" }.join(", ")}].to_unsafe"
      end
    end

    private def format_arg(i, type, io)
      io.print "arg#{i} = LibJNI::JValue.new; "
      case to_type(type)
      when "JBoolean" then io.puts "arg#{i}.z = x#{i} ? TRUE : FALSE"
      when "JByte"    then io.puts "arg#{i}.b = x#{i}"
      when "JChar"    then io.puts "arg#{i}.c = x#{i}"
      when "JShort"   then io.puts "arg#{i}.s = x#{i}"
      when "JInt"     then io.puts "arg#{i}.i = x#{i}"
      when "JLong"    then io.puts "arg#{i}.j = x#{i}"
      when "JFloat"   then io.puts "arg#{i}.f = x#{i}"
      when "JDouble"  then io.puts "arg#{i}.d = x#{i}"
      when "String"   then io.puts "arg#{i}.l = x#{i} ? JNI.call(:newStringUTF, x#{i}.to_unsafe) : NULL"
      else                 io.puts "arg#{i}.l = x#{i} ? x#{i}.to_unsafe : NULL"
      end
    end
  end
end
