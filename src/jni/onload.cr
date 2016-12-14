require "../jni"

fun jni_onload = JNI_OnLoad(vm : LibJNI::JavaVM*, reserved : Void*) : JNI::JInt
  JNI.vm = vm

  #Thread.new do
    GC.init

    begin
      LibCrystalMain.__crystal_main(0, nil)
    rescue ex
      Android.logger.error ex.message.to_s
      ex.backtrace.each { |line| Android.logger.error "     #{line}" }
    end

    JNI.version
  #end
end

# fun onUnload = JNI_OnUnload(vm : LibJNI::JavaVM*, reserved : Void*) : Void
#  Android.logger.info "JNI_OnUnload"
# end
