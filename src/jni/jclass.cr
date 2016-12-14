module JNI
  class JClass
    protected getter this : LibJNI::JClass

    #def self.new(object : LibJNI::JObject)
    #  new JNI.local(&.getObjectClass(object))
    #end

    def self.new(name : String)
      new JNI.lock(&.findClass(name))
    end

    def initialize(this : LibJNI::JClass)
      @this = JNI.lock(&.newGlobalRef(this))
    end

    def finalize
      JNI.lock(&.deleteGlobalRef(this))
    end

    def static_field_id(name, descriptor)
      JNI.lock(&.getStaticFieldID(this, name.to_unsafe, descriptor.to_unsafe))
    end

    def field_id(name, descriptor)
      JNI.lock(&.getFieldID(this, name.to_unsafe, descriptor.to_unsafe))
    end

    def static_method_id(name, descriptor)
      JNI.lock(&.getStaticMethodID(this, name.to_unsafe, descriptor.to_unsafe))
    end

    def method_id(name, descriptor)
      JNI.lock(&.getMethodID(this, name.to_unsafe, descriptor.to_unsafe))
    end

    def to_unsafe
      this
    end
  end
end
