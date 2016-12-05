require "./lib_jni"
require "./jni/jclass"
require "./jni/jobject"

class Thread
  def to_unsafe
    @th.not_nil!
  end
end

module JNI
  alias JBoolean = LibJNI::JBoolean
  alias JByte = LibJNI::JByte
  alias JChar = LibJNI::JChar
  alias JShort = LibJNI::JShort
  alias JInt = LibJNI::JInt
  alias JLong = LibJNI::JLong
  alias JFloat = LibJNI::JFloat
  alias JDouble = LibJNI::JDouble

  NULL = Pointer(Void*).null.as(LibJNI::JObject)

  VERSION_1_1 = LibJNI::VERSION_1_1
  VERSION_1_2 = LibJNI::VERSION_1_2
  VERSION_1_4 = LibJNI::VERSION_1_4
  VERSION_1_6 = LibJNI::VERSION_1_6

  @@version = VERSION_1_6

  def self.version=(@@version : Int32)
  end

  def self.version
    @@version
  end

  def self.vm=(@@vm : LibJNI::JavaVM*)
  end

  def self.vm
    @@vm || raise "FATAL: missing JNI.vm"
  end

  @@env = {} of LibC::PthreadT => LibJNI::Env*

  # Alaways returns a valid JNI::Env* for the curent thread.
  def self.env
    @@env[Thread.current.to_unsafe] ||= begin
      env = uninitialized LibJNI::Env**
      ret = vm.value.functions.value.getEnv.call(vm, env, version)
      case ret
      when LibJNI::OK
        env.value
      when LibJNI::EDETACHED
        attach_current_thread
      when LibJNI::EVERSION
        raise "FATAL: unsupported JNI version (0x#{version.to_s(16)})"
      else
        raise "FATAL: unknown return value for JavaVM->GetEnv: #{ret}"
      end
    end
  end

  def self.env=(env)
    if @@env[Thread.current.to_unsafe]?
      raise "FATAL: JNI.env already set for the current thread"
    end
    @@env[Thread.current.to_unsafe] = env
  end

  # FIXME: detach thread from JavaVM before it terminates
  protected def self.attach_current_thread
    args = LibJNI::JavaVMAttachArgs.new
    args.version = version
    env = uninitialized LibJNI::Env**
    ret = vm.value.functions.value.attachCurrentThread.call(vm, env, pointerof(args))
    raise "FATAL: JavaVM->AttachCurrentThread failed: #{ret}" unless ret == LibJNI::OK
    env.value
  end

  macro call(name, *args)
    JNI.env.value.functions.value.{{name.id}}.call(JNI.env, {{args.join(", ").id}})
  end

  # Returns a `String` from a `java.lang.String` and releases the original Java String.
  def self.to_string(jstr)
    ptr = JNI.call(:getStringUTFChars, jstr)
    begin
      String.new(ptr, JNI.call(:getStringLength, jstr))
    ensure
      JNI.call(:releaseStringUTFChars, jstr, ptr)
    end
  end
end
