require "./lib_jni"
require "./jni/env"
require "./jni/jclass"
require "./jni/jobject"

class Thread
  def to_unsafe
    @th.not_nil!
  end
end

module JNI
  class Exception < ::Exception
  end

  alias JBoolean = LibJNI::JBoolean
  alias JByte = LibJNI::JByte
  alias JChar = LibJNI::JChar
  alias JShort = LibJNI::JShort
  alias JInt = LibJNI::JInt
  alias JLong = LibJNI::JLong
  alias JFloat = LibJNI::JFloat
  alias JDouble = LibJNI::JDouble

  NULL = Pointer(Void*).null.as(LibJNI::JObject)
  TRUE = LibJNI::TRUE
  FALSE = LibJNI::FALSE

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

  # Yields an `Env` attached to the current thread. Checks and raises an
  # `Exception` if a Java exception is pending, otherwise returns the block
  # value.
  #
  # It is advised to limit the block to JNI calls only. Any call causing a fiber
  # context switch (e.g. sleep, IO, channels, ...) may cause a segfault. It is
  # also advised to never memoize the `Env` for the same reasons. An `Env` is
  # only ever valid for the current fiber it is currently running on.
  #
  # Example:
  # ```
  # message = JNI.lock do |env|
  #   jclass = env.getObjectClass(object)
  #   method_id = env.getMethodID(jclass, "toString".to_unsafe, "()Ljava.lang.String;".to_unsafe)
  #   jstr = env.callObjectMethodA(object, method_id, Pointer(JNI::Jvalue).null)
  #   JNI.to_string(jstr, env)
  # end
  # ```
  #
  # TODO: check whether the fiber needs to be locked to the thread for the
  #       duration of the method when Crystal becomes multithreaded (spoiler:
  #       most likely)
  def self.lock
    # puts "JNI.lock"
    env, attached = get_or_attach_env
    begin
      ret = yield env
      env.check_exception!
      ret
    ensure
      detach_current_thread if attached
    end
  end

  protected def self.get_or_attach_env
    # puts ":getEnv"
    env = uninitialized LibJNI::Env*
    ret = vm.value.functions.value.getEnv.call(vm, pointerof(env), version)

    case ret
    when LibJNI::OK
      {Env.new(env), false}
    when LibJNI::EDETACHED
      attach_current_thread
    when LibJNI::EVERSION
      raise "FATAL: unsupported JNI version (0x#{version.to_s(16)})"
    else
      raise "FATAL: JavaVM->GetEnv failed with an unknown error (#{ret})"
    end
  end

  def self.attach_current_thread
    # puts ":attachCurrentThread"
    args = LibJNI::JavaVMAttachArgs.new
    args.version = version
    env = uninitialized LibJNI::Env*
    ret = vm.value.functions.value.attachCurrentThread.call(vm, pointerof(env), pointerof(args))
    raise "FATAL: JavaVM->AttachCurrentThread failed: #{ret}" unless ret == LibJNI::OK
    {Env.new(env), true}
  end

  def self.detach_current_thread : Nil
    # puts ":detachCurrentThread"
    vm.value.functions.value.detachCurrentThread.call(vm)
  end

  def self.create_java_vm(options = nil)
    # puts ":createJavaVM"

    if options && options.any?
      vm_opts = Slice(LibJNI::JavaVMOption).new(options.size) do |i|
        opt = LibJNI::JavaVMOption.new
        opt.optionString = options[i]
        opt
      end
    else
      vm_opts = StaticArray(LibJNI::JavaVMOption, 0).new do
        LibJNI::JavaVMOption.new
      end
    end

    vm_args = LibJNI::JavaVMInitArgs.new
    vm_args.version = version
    vm_args.nOptions = vm_opts.size
    vm_args.options = vm_opts
    vm_args.ignoreUnrecognized = FALSE

    if LibJNI.createJavaVM(out vm, out env, pointerof(vm_args)) < 0
      raise "FATAL: failed to create VM"
    end

    {vm, env}
  end

  def self.destroy_java_vm(vm)
    # puts ":destroyJavaVM"
    vm.value.functions.value.destroyJavaVM.call(vm)
  end
end
