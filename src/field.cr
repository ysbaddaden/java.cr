module JavaP
  struct Field
    property visibility : String?
    property type : String?
    property java_name : String
    property descriptor : String

    @static : Bool

    def initialize(@visibility, @static, @type, @java_name, @descriptor)
      #p [:field, @visibility, @static, @type, @java_name, @descriptor]
    end

    def static?
      @static
    end

    def name
      static? ? java_name : java_name.underscore
    end

    def jni_method_name
      prefix = static? ? "Static" : ""
      case type
      when "void", Nil
        "call#{prefix}VoidField"
      when /\./, /Array\(.*\)/, "String"
        "call#{prefix}ObjectField"
      when "boolean", "byte", "char", "int", "long", "float", "double"
        "call#{prefix}#{type.to_s.camelcase}Field"
      else
        "call#{prefix}ObjectField"
      end
    end

    def jni_getter_method_name
      prefix = static? ? "Static" : ""
      case type
      when "void", Nil
        "get#{prefix}VoidField"
      when /\./, /Array\(.*\)/, "String"
        "get#{prefix}ObjectField"
      when "boolean", "byte", "char", "int", "long", "float", "double"
        "get#{prefix}#{type.to_s.camelcase}Field"
      else
        "get#{prefix}ObjectField"
      end
    end

    def jni_setter_method_name
      prefix = static? ? "Static" : ""
      case type
      when "void", Nil
        "set#{prefix}VoidField"
      when /\./, /Array\(.*\)/, "String"
        "set#{prefix}ObjectField"
      when "boolean", "byte", "char", "int", "long", "float", "double"
        "set#{prefix}#{type.to_s.camelcase}Field"
      else
        "set#{prefix}ObjectField"
      end
    end
  end
end
