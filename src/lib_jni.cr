lib LibJNI
  alias Char = LibC::Char

  alias JBoolean = UInt8
  alias JByte = Int8
  alias JChar = UInt16
  alias JShort = Int16
  alias JInt = Int32
  alias JLong = Int64
  alias JFloat = Float32
  alias JDouble = Float64
  alias JSize = JInt

  # alias VaList = Void*

  type JObject = Void*
  alias JClass = JObject
  alias JString = JObject
  alias JArray = JObject
  alias JObjectArray = JArray
  alias JBooleanArray = JArray
  alias JByteArray = JArray
  alias JCharArray = JArray
  alias JShortArray = JArray
  alias JIntArray = JArray
  alias JLongArray = JArray
  alias JFloatArray = JArray
  alias JDoubleArray = JArray
  alias JThrowable = JObject
  alias JWeak = JObject

  type JFieldID = Void*
  type JMethodID = Void*

  union JValue
    z : JBoolean
    b : JByte
    c : JChar
    s : JShort
    i : JInt
    j : JLong
    f : JFloat
    d : JDouble
    l : JObject
  end

  enum JObjectRefType
    Invalid    = 0
    Local      = 1
    Global     = 2
    WeakGlobal = 3
  end

  struct NativeMethod
    name : Char*
    signature : Char*
    fnPtr : Void*
  end

  struct NativeInterface
    reserved0 : Void*
    reserved1 : Void*
    reserved2 : Void*
    reserved3 : Void*

    getVersion : (Env*) -> JInt

    defineClass : (Env*, Char*, JObject, JByte*, JSize) -> JClass
    findClass : (Env*, Char*) -> JClass

    fromReflectedMethod : (Env*, JObject) -> JMethodID
    fromReflectedField : (Env*, JObject) -> JFieldID
    toReflectedMethod : (Env*, JClass, JMethodID, JBoolean) -> JObject

    getSuperclass : (Env*, JClass) -> JClass
    isAssignableFrom : (Env*, JClass, JClass) -> JBoolean

    toReflectedField : (Env*, JClass, JFieldID, JBoolean) -> JObject

    throw : (Env*, JThrowable) -> JInt
    throwNew : (Env*, JClass, Char*) -> JInt
    exceptionOccurred : (Env*) -> JThrowable
    exceptionDescribe : (Env*) -> Void
    exceptionClear : (Env*) -> Void
    fatalError : (Env*, Char*) -> Void

    pushLocalFrame : (Env*, JInt) -> JInt
    popLocalFrame : (Env*, JObject) -> JObject

    newGlobalRef : (Env*, JObject) -> JObject
    deleteGlobalRef : (Env*, JObject) -> Void
    deleteLocalRef : (Env*, JObject) -> Void
    isSameObject : (Env*, JObject, JObject) -> JBoolean

    newLocalRef : (Env*, JObject) -> JObject
    ensureLocalCapacity : (Env*, JInt) -> JInt

    allocObject : (Env*, JClass) -> JObject
    newObject : Void*  # (Env*, JClass, JMethodID, ...) ->  JObject
    newObjectV : Void* # (Env*, JClass, JMethodID, VaList) ->  JObject
    newObjectA : (Env*, JClass, JMethodID, JValue*) -> JObject

    getObjectClass : (Env*, JObject) -> JClass
    isInstanceOf : (Env*, JObject, JClass) -> JBoolean
    getMethodID : (Env*, JClass, Char*, Char*) -> JMethodID

    callObjectMethod : Void*  # (Env*, JObject, JMethodID, ...)                 ->  JObject
    callObjectMethodV : Void* # (Env*, JObject, JMethodID, VaList)            ->  JObject
    callObjectMethodA : (Env*, JObject, JMethodID, JValue*) -> JObject
    callBooleanMethod : Void*  # (Env*, JObject, JMethodID, ...)                ->  JBoolean
    callBooleanMethodV : Void* # (Env*, JObject, JMethodID, VaList)           ->  JBoolean
    callBooleanMethodA : (Env*, JObject, JMethodID, JValue*) -> JBoolean
    callByteMethod : Void*  # (Env*, JObject, JMethodID, ...)                   ->  JByte
    callByteMethodV : Void* # (Env*, JObject, JMethodID, VaList)              ->  JByte
    callByteMethodA : (Env*, JObject, JMethodID, JValue*) -> JByte
    callCharMethod : Void*  # (Env*, JObject, JMethodID, ...)                   ->  JChar
    callCharMethodV : Void* # (Env*, JObject, JMethodID, VaList)              ->  JChar
    callCharMethodA : (Env*, JObject, JMethodID, JValue*) -> JChar
    callShortMethod : Void*  # (Env*, JObject, JMethodID, ...)                  ->  JShort
    callShortMethodV : Void* # (Env*, JObject, JMethodID, VaList)             ->  JShort
    callShortMethodA : (Env*, JObject, JMethodID, JValue*) -> JShort
    callIntMethod : Void*  # (Env*, JObject, JMethodID, ...)                    ->  JInt
    callIntMethodV : Void* # (Env*, JObject, JMethodID, VaList)               ->  JInt
    callIntMethodA : (Env*, JObject, JMethodID, JValue*) -> JInt
    callLongMethod : Void*  # (Env*, JObject, JMethodID, ...)                   ->  JLong
    callLongMethodV : Void* # (Env*, JObject, JMethodID, VaList)              ->  JLong
    callLongMethodA : (Env*, JObject, JMethodID, JValue*) -> JLong
    callFloatMethod : Void*  # (Env*, JObject, JMethodID, ...)                  ->  JFloat
    callFloatMethodV : Void* # (Env*, JObject, JMethodID, VaList)             ->  JFloat
    callFloatMethodA : (Env*, JObject, JMethodID, JValue*) -> JFloat
    callDoubleMethod : Void*  # (Env*, JObject, JMethodID, ...)                 ->  JDouble
    callDoubleMethodV : Void* # (Env*, JObject, JMethodID, VaList)            ->  JDouble
    callDoubleMethodA : (Env*, JObject, JMethodID, JValue*) -> JDouble
    callVoidMethod : Void*  # (Env*, JObject, JMethodID, ...)                   ->  Void
    callVoidMethodV : Void* # (Env*, JObject, JMethodID, VaList)              ->  Void
    callVoidMethodA : (Env*, JObject, JMethodID, JValue*) -> Void

    callNonvirtualObjectMethod : Void*  # (Env*, JObject, JClass, JMethodID, ...)       -> JObject
    callNonvirtualObjectMethodV : Void* # (Env*, JObject, JClass, JMethodID, VaList)  -> JObject
    callNonvirtualObjectMethodA : (Env*, JObject, JClass, JMethodID, JValue*) -> JObject
    callNonvirtualBooleanMethod : Void*  # (Env*, JObject, JClass, JMethodID, ...)      -> JBoolean
    callNonvirtualBooleanMethodV : Void* # (Env*, JObject, JClass, JMethodID, VaList) -> JBoolean
    callNonvirtualBooleanMethodA : (Env*, JObject, JClass, JMethodID, JValue*) -> JBoolean
    callNonvirtualByteMethod : Void*  # (Env*, JObject, JClass, JMethodID, ...)         -> JByte
    callNonvirtualByteMethodV : Void* # (Env*, JObject, JClass, JMethodID, VaList)    -> JByte
    callNonvirtualByteMethodA : (Env*, JObject, JClass, JMethodID, JValue*) -> JByte
    callNonvirtualCharMethod : Void*  # (Env*, JObject, JClass, JMethodID, ...)         -> JChar
    callNonvirtualCharMethodV : Void* # (Env*, JObject, JClass, JMethodID, VaList)    -> JChar
    callNonvirtualCharMethodA : (Env*, JObject, JClass, JMethodID, JValue*) -> JChar
    callNonvirtualShortMethod : Void*  # (Env*, JObject, JClass, JMethodID, ...)        -> JShort
    callNonvirtualShortMethodV : Void* # (Env*, JObject, JClass, JMethodID, VaList)   -> JShort
    callNonvirtualShortMethodA : (Env*, JObject, JClass, JMethodID, JValue*) -> JShort
    callNonvirtualIntMethod : Void*  # (Env*, JObject, JClass, JMethodID, ...)          -> JInt
    callNonvirtualIntMethodV : Void* # (Env*, JObject, JClass, JMethodID, VaList)     -> JInt
    callNonvirtualIntMethodA : (Env*, JObject, JClass, JMethodID, JValue*) -> JInt
    callNonvirtualLongMethod : Void*  # (Env*, JObject, JClass, JMethodID, ...)         -> JLong
    callNonvirtualLongMethodV : Void* # (Env*, JObject, JClass, JMethodID, VaList)    -> JLong
    callNonvirtualLongMethodA : (Env*, JObject, JClass, JMethodID, JValue*) -> JLong
    callNonvirtualFloatMethod : Void*  # (Env*, JObject, JClass, JMethodID, ...)        -> JFloat
    callNonvirtualFloatMethodV : Void* # (Env*, JObject, JClass, JMethodID, VaList)   -> JFloat
    callNonvirtualFloatMethodA : (Env*, JObject, JClass, JMethodID, JValue*) -> JFloat
    callNonvirtualDoubleMethod : Void*  # (Env*, JObject, JClass, JMethodID, ...)       -> JDouble
    callNonvirtualDoubleMethodV : Void* # (Env*, JObject, JClass, JMethodID, VaList)  -> JDouble
    callNonvirtualDoubleMethodA : (Env*, JObject, JClass, JMethodID, JValue*) -> JDouble
    callNonvirtualVoidMethod : Void*  # (Env*, JObject, JClass, JMethodID, ...)         -> Void
    callNonvirtualVoidMethodV : Void* # (Env*, JObject, JClass, JMethodID, VaList)    -> Void
    callNonvirtualVoidMethodA : (Env*, JObject, JClass, JMethodID, JValue*) -> Void

    getFieldID : (Env*, JClass, Char*, Char*) -> JFieldID

    getObjectField : (Env*, JObject, JFieldID) -> JObject
    getBooleanField : (Env*, JObject, JFieldID) -> JBoolean
    getByteField : (Env*, JObject, JFieldID) -> JByte
    getCharField : (Env*, JObject, JFieldID) -> JChar
    getShortField : (Env*, JObject, JFieldID) -> JShort
    getIntField : (Env*, JObject, JFieldID) -> JInt
    getLongField : (Env*, JObject, JFieldID) -> JLong
    getFloatField : (Env*, JObject, JFieldID) -> JFloat
    getDoubleField : (Env*, JObject, JFieldID) -> JDouble

    setObjectField : (Env*, JObject, JFieldID, JObject) -> Void
    setBooleanField : (Env*, JObject, JFieldID, JBoolean) -> Void
    setByteField : (Env*, JObject, JFieldID, JByte) -> Void
    setCharField : (Env*, JObject, JFieldID, JChar) -> Void
    setShortField : (Env*, JObject, JFieldID, JShort) -> Void
    setIntField : (Env*, JObject, JFieldID, JInt) -> Void
    setLongField : (Env*, JObject, JFieldID, JLong) -> Void
    setFloatField : (Env*, JObject, JFieldID, JFloat) -> Void
    setDoubleField : (Env*, JObject, JFieldID, JDouble) -> Void

    getStaticMethodID : (Env*, JClass, Char*, Char*) -> JMethodID

    callStaticObjectMethod : Void*  # (Env*, JClass, JMethodID, ...)             ->   JObject
    callStaticObjectMethodV : Void* # (Env*, JClass, JMethodID, VaList)         ->  JObject
    callStaticObjectMethodA : (Env*, JClass, JMethodID, JValue*) -> JObject
    callStaticBooleanMethod : Void*  # (Env*, JClass, JMethodID, ...)            ->   JBoolean
    callStaticBooleanMethodV : Void* # (Env*, JClass, JMethodID, VaList)        ->  JBoolean
    callStaticBooleanMethodA : (Env*, JClass, JMethodID, JValue*) -> JBoolean
    callStaticByteMethod : Void*  # (Env*, JClass, JMethodID, ...)               ->   JByte
    callStaticByteMethodV : Void* # (Env*, JClass, JMethodID, VaList)           ->  JByte
    callStaticByteMethodA : (Env*, JClass, JMethodID, JValue*) -> JByte
    callStaticCharMethod : Void*  # (Env*, JClass, JMethodID, ...)               ->   JChar
    callStaticCharMethodV : Void* # (Env*, JClass, JMethodID, VaList)           ->  JChar
    callStaticCharMethodA : (Env*, JClass, JMethodID, JValue*) -> JChar
    callStaticShortMethod : Void*  # (Env*, JClass, JMethodID, ...)              ->   JShort
    callStaticShortMethodV : Void* # (Env*, JClass, JMethodID, VaList)          ->  JShort
    callStaticShortMethodA : (Env*, JClass, JMethodID, JValue*) -> JShort
    callStaticIntMethod : Void*  # (Env*, JClass, JMethodID, ...)                ->   JInt
    callStaticIntMethodV : Void* # (Env*, JClass, JMethodID, VaList)            ->  JInt
    callStaticIntMethodA : (Env*, JClass, JMethodID, JValue*) -> JInt
    callStaticLongMethod : Void*  # (Env*, JClass, JMethodID, ...)               ->   JLong
    callStaticLongMethodV : Void* # (Env*, JClass, JMethodID, VaList)           ->  JLong
    callStaticLongMethodA : (Env*, JClass, JMethodID, JValue*) -> JLong
    callStaticFloatMethod : Void*  # (Env*, JClass, JMethodID, ...)              ->   JFloat
    callStaticFloatMethodV : Void* # (Env*, JClass, JMethodID, VaList)          ->  JFloat
    callStaticFloatMethodA : (Env*, JClass, JMethodID, JValue*) -> JFloat
    callStaticDoubleMethod : Void*  # (Env*, JClass, JMethodID, ...)             ->   JDouble
    callStaticDoubleMethodV : Void* # (Env*, JClass, JMethodID, VaList)         ->  JDouble
    callStaticDoubleMethodA : (Env*, JClass, JMethodID, JValue*) -> JDouble
    callStaticVoidMethod : Void*  # (Env*, JClass, JMethodID, ...)               ->   Void
    callStaticVoidMethodV : Void* # (Env*, JClass, JMethodID, VaList)           ->  Void
    callStaticVoidMethodA : (Env*, JClass, JMethodID, JValue*) -> Void

    getStaticFieldID : (Env*, JClass, Char*, Char*) -> JFieldID

    getStaticObjectField : (Env*, JClass, JFieldID) -> JObject
    getStaticBooleanField : (Env*, JClass, JFieldID) -> JBoolean
    getStaticByteField : (Env*, JClass, JFieldID) -> JByte
    getStaticCharField : (Env*, JClass, JFieldID) -> JChar
    getStaticShortField : (Env*, JClass, JFieldID) -> JShort
    getStaticIntField : (Env*, JClass, JFieldID) -> JInt
    getStaticLongField : (Env*, JClass, JFieldID) -> JLong
    getStaticFloatField : (Env*, JClass, JFieldID) -> JFloat
    getStaticDoubleField : (Env*, JClass, JFieldID) -> JDouble

    setStaticObjectField : (Env*, JClass, JFieldID, JObject) -> Void
    setStaticBooleanField : (Env*, JClass, JFieldID, JBoolean) -> Void
    setStaticByteField : (Env*, JClass, JFieldID, JByte) -> Void
    setStaticCharField : (Env*, JClass, JFieldID, JChar) -> Void
    setStaticShortField : (Env*, JClass, JFieldID, JShort) -> Void
    setStaticIntField : (Env*, JClass, JFieldID, JInt) -> Void
    setStaticLongField : (Env*, JClass, JFieldID, JLong) -> Void
    setStaticFloatField : (Env*, JClass, JFieldID, JFloat) -> Void
    setStaticDoubleField : (Env*, JClass, JFieldID, JDouble) -> Void

    newString : (Env*, JChar*, JSize) -> JString
    getStringLength : (Env*, JString) -> JSize
    getStringChars : (Env*, JString, JBoolean*) -> JChar*
    releaseStringChars : (Env*, JString, JChar*) -> Void
    newStringUTF : (Env*, Char*) -> JString
    getStringUTFLength : (Env*, JString) -> JSize
    # JNI spec says this returns JByte*, but that's inconsistent
    getStringUTFChars : (Env*, JString, JBoolean*) -> Char*
    releaseStringUTFChars : (Env*, JString, Char*) -> Void

    getArrayLength : (Env*, JArray) -> JSize
    newObjectArray : (Env*, JSize, JClass, JObject) -> JObjectArray
    getObjectArrayElement : (Env*, JObjectArray, JSize) -> JObject
    setObjectArrayElement : (Env*, JObjectArray, JSize, JObject) -> Void

    newBooleanArray : (Env*, JSize) -> JBooleanArray
    newByteArray : (Env*, JSize) -> JByteArray
    newCharArray : (Env*, JSize) -> JShortArray
    newShortArray : (Env*, JSize) -> JShortArray
    newIntArray : (Env*, JSize) -> JIntArray
    newLongArray : (Env*, JSize) -> JLongArray
    newFloatArray : (Env*, JSize) -> JFloatArray
    newDoubleArray : (Env*, JSize) -> JDoubleArray

    getBooleanArrayElements : (Env*, JBooleanArray, JBoolean*) -> JBoolean*
    getByteArrayElements : (Env*, JByteArray, JBoolean*) -> JByte*
    getCharArrayElements : (Env*, JShortArray, JBoolean*) -> JChar*
    getShortArrayElements : (Env*, JShortArray, JBoolean*) -> JShort*
    getIntArrayElements : (Env*, JIntArray, JBoolean*) -> JInt*
    getLongArrayElements : (Env*, JLongArray, JBoolean*) -> JLong*
    getFloatArrayElements : (Env*, JFloatArray, JBoolean*) -> JFloat*
    getDoubleArrayElements : (Env*, JDoubleArray, JBoolean*) -> JDouble*

    releaseBooleanArrayElements : (Env*, JBooleanArray, JBoolean*, JInt) -> Void
    releaseByteArrayElements : (Env*, JByteArray, JByte*, JInt) -> Void
    releaseCharArrayElements : (Env*, JShortArray, JChar*, JInt) -> Void
    releaseShortArrayElements : (Env*, JShortArray, JShort*, JInt) -> Void
    releaseIntArrayElements : (Env*, JIntArray, JInt*, JInt) -> Void
    releaseLongArrayElements : (Env*, JLongArray, JLong*, JInt) -> Void
    releaseFloatArrayElements : (Env*, JFloatArray, JFloat*, JInt) -> Void
    releaseDoubleArrayElements : (Env*, JDoubleArray, JDouble*, JInt) -> Void

    getBooleanArrayRegion : (Env*, JBooleanArray, JSize, JSize, JBoolean*) -> Void
    getByteArrayRegion : (Env*, JByteArray, JSize, JSize, JByte*) -> Void
    getCharArrayRegion : (Env*, JShortArray, JSize, JSize, JChar*) -> Void
    getShortArrayRegion : (Env*, JShortArray, JSize, JSize, JShort*) -> Void
    getIntArrayRegion : (Env*, JIntArray, JSize, JSize, JInt*) -> Void
    getLongArrayRegion : (Env*, JLongArray, JSize, JSize, JLong*) -> Void
    getFloatArrayRegion : (Env*, JFloatArray, JSize, JSize, JFloat*) -> Void
    getDoubleArrayRegion : (Env*, JDoubleArray, JSize, JSize, JDouble*) -> Void

    # spec shows these without some jni.h do, some don't
    setBooleanArrayRegion : (Env*, JBooleanArray, JSize, JSize, JBoolean*) -> Void
    setByteArrayRegion : (Env*, JByteArray, JSize, JSize, JByte*) -> Void
    setCharArrayRegion : (Env*, JShortArray, JSize, JSize, JChar*) -> Void
    setShortArrayRegion : (Env*, JShortArray, JSize, JSize, JShort*) -> Void
    setIntArrayRegion : (Env*, JIntArray, JSize, JSize, JInt*) -> Void
    setLongArrayRegion : (Env*, JLongArray, JSize, JSize, JLong*) -> Void
    setFloatArrayRegion : (Env*, JFloatArray, JSize, JSize, JFloat*) -> Void
    setDoubleArrayRegion : (Env*, JDoubleArray, JSize, JSize, JDouble*) -> Void

    registerNatives : (Env*, JClass, NativeMethod*, JInt) -> JInt
    unregisterNatives : (Env*, JClass) -> JInt
    monitorEnter : (Env*, JObject) -> JInt
    monitorExit : (Env*, JObject) -> JInt
    getJavaVM : (Env*, JavaVM**) -> JInt

    getStringRegion : (Env*, JString, JSize, JSize, JChar*) -> Void
    getStringUTFRegion : (Env*, JString, JSize, JSize, Char*) -> Void

    getPrimitiveArrayCritical : (Env*, JArray, JBoolean*) -> Void*
    releasePrimitiveArrayCritical : (Env*, JArray, Void*, JInt) -> Void

    getStringCritical : (Env*, JString, JBoolean*) -> JChar*
    releaseStringCritical : (Env*, JString, JChar*) -> Void

    newWeakGlobalRef : (Env*, JObject) -> JWeak
    deleteWeakGlobalRef : (Env*, JWeak) -> Void

    exceptionCheck : (Env*) -> JBoolean

    newDirectByteBuffer : (Env*, Void*, JLong) -> JObject
    getDirectBufferAddress : (Env*, JObject) -> Void*
    getDirectBufferCapacity : (Env*, JObject) -> JLong

    # added in JNI 1.6
    getObjectRefType : (Env*, JObject) -> JObjectRefType
  end

  struct InvokeInterface
    reserved0 : Void*
    reserved1 : Void*
    reserved2 : Void*

    destroyJavaVM : (JavaVM*) -> JInt
    attachCurrentThread : (JavaVM*, Env**, JavaVMAttachArgs*) -> JInt
    detachCurrentThread : (JavaVM*) -> JInt
    getEnv : (JavaVM*, Env**, JInt) -> JInt
    attachCurrentThreadAsDaemon : (JavaVM*, Env**, Void*) -> JInt
  end

  struct JavaVMAttachArgs
    version : JInt  # must be >= VERSION_1_2
    name : Char*    # NULL or name of thread as modified UTF-8 str
    group : JObject # global ref of a ThreadGroup object, or NULL
  end

  # JNI 1.2+ initialization.  (As of 1.6, the pre-1.2 structures are no
  # longer supported.)
  struct JavaVMOption
    optionString : Char*
    extraInfo : Void*
  end

  struct JavaVMInitArgs
    version : JInt # use VERSION_1_2 or later
    nOptions : JInt
    options : JavaVMOption*
    ignoreUnrecognized : JBoolean
  end

  struct Env
    functions : NativeInterface*
  end

  struct JavaVM
    functions : InvokeInterface*
  end

  # getDefaultJavaVMInitArgs = JNI_GetDefaultJavaVMInitArgs(Void*)
  # createJavaVM = JNI_CreateJavaVM(JavaVM**, Env**, Void*)
  # getCreatedJavaVMs = JNI_GetCreatedJavaVMs(JavaVM**, Size, Size*)

  fun onLoad = JNI_OnLoad(vm : JavaVM*, reserved : Void*) : JInt
  fun onUnload = JNI_OnUnload(vm : JavaVM*, reserved : Void*) : Void

  FALSE = 0
  TRUE  = 1

  VERSION_1_1 = 0x00010001
  VERSION_1_2 = 0x00010002
  VERSION_1_4 = 0x00010004
  VERSION_1_6 = 0x00010006

  OK        =  0
  ERR       = -1
  EDETACHED = -2
  EVERSION  = -3

  COMMIT = 1
  ABORT  = 2
end
