require "./parser"

module JavaP
  class Formatter
    private getter parser : Parser

    @types : Hash(String, Parser)

    def initialize(@parser, @types)
      @forall = [] of String
    end

    def to_crystal(io)
      namespace = parser.class_name.split('.')
      class_name = namespace.pop

      # require
      format_requires(namespace, class_name, io)

      # class definition

      namespace.each_with_index do |ns, i|
        io.puts "module #{to_type(ns, force: true)}"
        io.puts "include JNI\n\n" if i == 0
      end

      if parser.interface?
        # interfaces become a module (eg: argument restriction)
        name = to_type(class_name, force: true)
        io.puts "module #{name}"
        parser.extends.each do |type|
          if @types.has_key?(type)
            io.puts "include #{to_type(type, exact: true)}"
          end
        end
        io.puts

        # interfaces also become a class that include the above module (used for
        # wrapping return types)
        io.puts "class InterfaceObject < JObject"
        io.puts "include #{name}"
        io.puts "end"
        io.puts
      else
        # classes simply become a class
        io.print "class #{to_type(class_name, force: true)}"
        if (type = parser.extends.first?) && @types.has_key?(type)
          io.puts " < #{to_type(type, exact: true, force: true)}"
        else
          io.puts " < JObject"
        end

        #if parser.extends.size > 1
        #  parser.extends[1..-1].each do |type|
        #    if @types.has_key?(type)
        #      io.puts "# extend #{to_type(type, exact: true)}"
        #    end
        #  end
        #end

        parser.implements.each do |type|
          if @types.has_key?(type)
            io.puts "include #{to_type(type, exact: true)}"
          end
        end
        io.puts
      end

      unless parser.interface?
        io.puts <<-JCLASS
        def self.jclass
          # @@jclass ||= JClass.new("#{parser.descriptor}")
          JClass.new("#{parser.descriptor}")
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

    private def format_requires(namespace, class_name, io)
      requires = Set(String).new

      parser.extends.each do |type|
        if @types.has_key?(type)
          requires << type
        end
      end

      parser.implements.each do |type|
        if @types.has_key?(type)
          requires << type
        end
      end

      # FIXME: requiring everything eventually leads to issues in load order.
      #        for example A -> B -> A will fail if A includes B.
      #parser.all_types.each do |type|
      #  if @types.has_key?(type)
      #    requires << type
      #  end
      #end

      io.puts "require \"java/jni\""

      requires.to_a.sort.each do |type|
        path = type.split('.').map(&.underscore).join('/')
        path = ("../" * namespace.size) + path.gsub('$', '_')
        io.puts "require #{path.inspect}"
      end

      if idx = class_name.index('$')
        io.puts "require \"./#{class_name[0...idx].underscore}\""
      end
    end

    private def to_arg_type(str)
      if str == "boolean"
        "Bool"
      else
        name = to_type(str)
        name.includes?("::") ? "#{name}?" : name
      end
    end

    private def to_type(str, exact = false, force = false)
      case str
      when "boolean", "byte", "char", "short", "int", "long", "float", "double"
        # primitive
        "J#{str.camelcase}"
      when "java.lang.String", "java.lang.CharSequence"
        # FIXME: maybe the Crystal String class should extend `java.lang.CharSequence` instead?
        #        that would be accepted in arguments, and return types should
        #        assume the `java.lang.CharSequence` to be a `String`?
        exact ? to_crystal_type(str, force) : "String"
      when .starts_with?('?')
        "W#{@forall.size}".tap { |type| @forall << type }
      else
        if str.ends_with?("...")
          # variadic (last argument)
          "#{to_type(str[0...-3], force)}..."
        elsif str.ends_with?("[]")
          "Array(#{to_type(str[0...-2], force)})"
        elsif str.includes?('<') || str.includes?(',')
          to_generic_type(str, force)
        else
          to_crystal_type(str, force)
        end
      end
    end

    private def to_generic_type(type, force)
      parts = type.gsub('$', '_').split(/([<>, ?])/)

      unless force || @types.has_key?(parts.first)
        return "JObject"
      end

      String.build do |str|
        parts.each do |word|
          case word
          when "<"
            str << '('
          when ">"
            str << ')'
          when ","
            str << ", "
          when "?"
            # FIXME: invalid for return type
            str << "W#{@forall.size}".tap { |type| @forall << type }
          when "", " "
            # skip
          else
            str << to_type(word, force)
          end
        end
      end
    end

    private def to_crystal_type(type, force)
      if force || @types.has_key?(type)
        type.split('.')
          .map(&.camelcase)
          .join("::")
          .gsub('$', '_')
      else
        "JObject"
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
        io.puts "# NOTE: *x#{i}* is actually a `#{arg}`" if type == "JObject"
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

      # OPTIMIZE: local memoization
      io.puts "klass = self.jclass"

      # call jni method
      if parser.constructor?(m)
        io.puts "mid = jclass.method_id(\"<init>\", #{m.descriptor.inspect})"
        io.puts "new JNI.call(:newObjectA, jclass.to_unsafe, mid, #{args})"
      else
        if m.static?
          io.puts "mid = jclass.static_method_id(#{m.java_name.inspect}, #{m.descriptor.inspect})"
          io.puts "ret = JNI.call(:#{m.jni_method_name}, jclass.to_unsafe, mid, #{args})"
        else
          io.puts "mid = jclass.method_id(#{m.java_name.inspect}, #{m.descriptor.inspect})"
          io.puts "ret = JNI.call(:#{m.jni_method_name}, this, mid, #{args})"
        end
        wrap_return_type(m, "ret", io)
      end

      io.puts "end"
      io.puts
    end

    private def wrap_return_type(x, ret, io)
      case x.jni_method_name
      when .includes?("Object")
        if x.type == "java.lang.String" || x.type == "java.lang.CharSequence"
          io.puts "JNI.to_string(#{ret})"
        else
          if @types[x.type.to_s]?.try(&.interface?)
            io.puts "#{to_type(x.type.to_s)}::InterfaceObject.new(#{ret})"
          else
            io.puts "#{to_type(x.type.to_s)}.new(#{ret})"
          end
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
