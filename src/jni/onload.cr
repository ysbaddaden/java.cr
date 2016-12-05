require "../jni"

fun jni_onload = JNI_OnLoad(vm : JNI::JavaVM, reserved : Void*) : JNI::JInt
  GC.init
  JNI.vm = vm

  begin
    LibCrystalMain.__crystal_main(0, nil)
  rescue ex
    Android.logger.error ex.message.to_s
    ex.backtrace.each { |line| Android.logger.error "     #{line}" }
  end

  LibJNI::VERSION_1_6
end

# fun onUnload = JNI_OnUnload(vm : LibJNI::JavaVM*, reserved : Void*) : Void
#  Android.logger.info "JNI_OnUnload"
# end
