require "../lib_jni"

module JNI
  struct Env
    protected def initialize(@env : LibJNI::Env*)
    end

    # Refer to
    # <http://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/functions.html#FindClass
    def findClass(descriptor)
      @env.value.functions.value.findClass.call(@env, descriptor.to_unsafe)
    end

    # Refer to
    # <http://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/functions.html#GetStaticFieldID
    def getStaticFieldID(jclass, name, descriptor)
      @env.value.functions.value.getStaticFieldID.call(@env, jclass, name.to_unsafe, descriptor.to_unsafe)
    end

    # Refer to
    # <http://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/functions.html#GetFieldID
    def getFieldID(jclass, name, descriptor)
      @env.value.functions.value.getFieldID.call(@env, jclass, name.to_unsafe, descriptor.to_unsafe)
    end

    # Refer to
    # <http://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/functions.html#GetStaticMethodID
    def getStaticMethodID(jclass, name, descriptor)
      @env.value.functions.value.getStaticMethodID.call(@env, jclass, name.to_unsafe, descriptor.to_unsafe)
    end

    # Refer to
    # <http://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/functions.html#GetMethodID
    def getMethodID(jclass, name, descriptor)
      @env.value.functions.value.getMethodID.call(@env, jclass, name.to_unsafe, descriptor.to_unsafe)
    end

    # Automatically creates delegation methods.
    macro method_missing(call)
      # Refer to
      # <http://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/functions.html#{{call.name.underscore.camelcase.id}}>
      def {{call.name.id}}({{call.args.join(", ").id}})
        {% if call.args.size > 0 %}
          @env.value.functions.value.{{call.name.id}}.call(@env, {{call.args.join(", ").id}})
        {% else %}
          @env.value.functions.value.{{call.name.id}}.call(@env)
        {% end %}
      end
    end

    # Raises an `Exception` is a Java exception was raised, otherwise does
    # nothing.
    def check_exception!
      jthrowable = exceptionOccurred()
      return if jthrowable.null?

      # handle the Java exception
      exceptionClear()

      # get exception message
      jclass = getObjectClass(jthrowable)
      method_id = getMethodID(jclass, "toString", "()Ljava/lang/String;")
      jstr = callObjectMethodA(jthrowable, method_id, Pointer(LibJNI::JValue).null)

      # raise a Crystal exception
      raise Exception.new(to_string(jstr))
    end

    # Gets a `String` out of a `java.lang.String`.
    def to_string(jstr : LibJNI::JObject)
      is_copy = 0_u8
      ptr = self.getStringUTFChars(jstr, pointerof(is_copy))
      check_exception!
      begin
        String.new(ptr, self.getStringUTFLength(jstr))
      ensure
        self.releaseStringUTFChars(jstr, ptr)
      end
    end
  end
end
