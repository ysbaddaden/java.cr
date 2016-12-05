module JNI
  class JClass
    protected getter this : LibJNI::JClass

    def self.new(object : LibJNI::JObject)
      new JNI.call(:getObjectClass, object)
    end

    def self.new(name : String)
      new JNI.call(:findClass, name.to_unsafe)
    end

    def initialize(this : LibJNI::JObject)
      @this = JNI.call(:newGlobalRef, this)
    end

    def finalize
      JNI.call(:deleteGlobalRef, this)
    end

    def static_field_id(name, descriptor)
      JNI.call(:getStaticFieldID, this, name.to_unsafe, descriptor.to_unsafe)
    end

    def field_id(name, descriptor)
      JNI.call(:getFieldID, this, name.to_unsafe, descriptor.to_unsafe)
    end

    def method_id(name, descriptor)
      JNI.call(:getMethodID, this, name.to_unsafe, descriptor.to_unsafe)
    end

    def to_unsafe
      this
    end
  end
end
