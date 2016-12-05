module JNI
  class JObject
    protected getter this : LibJNI::JObject

    def self.new(obj : JObject)
      new(obj.to_unsafe)
    end

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
      self == other.to_unsafe
    end

    def ==(other : LibJNI::JObject)
      JNI.call(:isSameObject, this, other) == LibJNI::TRUE
    end

    def ==(other)
      false
    end

    def to_unsafe
      this
    end
  end
end
