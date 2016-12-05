module JNI
  class JObject
    protected getter this : LibJNI::JObject

    def initialize(this : LibJNI::JObject)
      @this = JNI.call(:newGlobalRef, this)
    end

    def finalize
      JNI.call(:deleteGlobalRef, this)
    end

    def jclass
      if self.class.responds_to?(:jclass)
        self.class.jclass
      else
        @jclass ||= JClass.new(this)
      end
    end

    def ==(other : JObject)
      JNI.call(:isSameObject, this, other.to_unsafe) == LibJNI::TRUE
    end

    def ==(other)
      false
    end

    def to_unsafe
      this
    end
  end
end
