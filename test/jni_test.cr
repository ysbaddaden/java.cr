require "./test_helper"
require "../src/main"

class JNITest < Minitest::Test
  def test_calls_static_method
    JNI.lock do |env|
      jclass = env.findClass("java/lang/Long")

      method_id = env.getStaticMethodID(jclass, "toString", "(J)Ljava/lang/String;")
      arg = LibJNI::JValue.new; arg.j = Int64::MAX
      jstr = env.callStaticObjectMethodA(jclass, method_id, pointerof(arg))

      assert_equal Int64::MAX.to_s, env.to_string(jstr)
    end
  end

  def test_instantiates_object_then_calls_method
    JNI.lock do |env|
      jclass = env.findClass("java/lang/Integer")

      method_id = env.getMethodID(jclass, "<init>", "(I)V")
      arg = LibJNI::JValue.new; arg.i = Int32::MAX
      integer = env.newObjectA(jclass, method_id, pointerof(arg))

      method_id = env.getMethodID(jclass, "toString", "()Ljava/lang/String;")
      none = Pointer(LibJNI::JValue).null
      jstr = env.callObjectMethodA(integer, method_id, none)

      assert_equal Int32::MAX.to_s, env.to_string(jstr)
    end
  end

  def test_lock_eventually_checks_for_java_exception
    ex = assert_raises(JNI::Exception) do
      JNI.lock do |env|
        jclass = env.findClass("java/lang/Integer")
        method_id = env.getStaticMethodID(jclass, "someUnknownMethodName", "(J)Ljava/lang/String;")
      end
    end
    assert_equal "java.lang.NoSuchMethodError: someUnknownMethodName", ex.message
  end
end
