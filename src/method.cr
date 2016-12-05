module JavaP
  struct Method
    property visibility : String?
    property forall : String?
    property type : String?
    property java_name : String
    property args : Array(String)
    property throws : Array(String)
    property descriptor : String

    @abstract : Bool
    @static : Bool
    @variadic : Bool

    def initialize(@visibility, @abstract, @static, @forall, @type, @java_name, @args, @variadic, @throws, @descriptor)
    end

    def abstract?
      @abstract
    end

    def static?
      @static
    end

    def variadic?
      @variadic
    end

    def name
      java_name.underscore
    end

    def getter?
      @java_name.starts_with?("get") && args.size == 0
    end

    def setter?
      @java_name.starts_with?("set") && args.size == 1
    end

    def jni_method_name
      prefix = static? ? "Static" : ""
      case type
      when "void", Nil
        "call#{prefix}VoidMethodA"
      when /\./, /Array\(.*\)/, "String"
        "call#{prefix}ObjectMethodA"
      when "boolean", "byte", "char", "int", "long", "float", "double"
        "call#{prefix}#{type.to_s.camelcase}MethodA"
      else
        "call#{prefix}ObjectMethodA"
      end
    end
  end
end
