require "minitest/autorun"
require "../src/jni"
require "../src/main"

#JNI.version = JNI::VERSION_1_6
JNI.vm, _ = JNI.create_java_vm ["-verbose:jni"]

Minitest.after_run do
  JNI.destroy_java_vm(JNI.vm)
end
