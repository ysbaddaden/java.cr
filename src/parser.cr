require "./lexer"
require "./field"
require "./method"

module JavaP
  class Parser
    getter source : String
    getter visibility : String
    getter abstract : Bool
    getter class_name : String
    getter extends : String?
    getter implements : Array(String)
    getter fields : Array(Field)
    getter methods : Array(Method)
    getter interface : Bool

    private getter lexer

    def self.parse(source)
      parser = new(source)
      parser.parse
      parser
    end

    # OPTIMIZE: pass and IO object to the Lexer instead of a String
    def self.new(source : String)
      new Lexer.new(source)
    end

    def initialize(@lexer : Lexer)
      @class_name = @source = ""
      @interface = @abstract = false
      @visibility = "public"
      @implements = [] of String
      @buffer = [] of Char | String
      @fields = [] of Field
      @methods = [] of Method
    end

    def abstract?
      @abstract
    end

    def interface?
      @interface
    end

    def parse
      parse_source
      parse_class
    end

    def descriptor
      name = class_name.gsub('.', '/')
      if idx = name.index('<')
        name[0...idx]
      else
        name
      end
    end

    def constructor?(method)
      class_name.gsub('$', '.').starts_with?(method.java_name.gsub('$', '.'))
    end

    private def parse_source
      expect "Compiled"
      expect "from"
      @source = lex.to_s
    end

    private def parse_class
      loop do
        case token = lex
        when "public", "protected", "private"
          @visibility = token.to_s
        when "abstract"
          @abstract = true
        when "class"
          break
        when "interface"
          @interface = true
          return
        when "final"
          # skip
        else
          raise "Expected public, protected, private, abstract, final or class but got #{token}"
        end
      end

      @class_name = parse_type

      loop do
        case token = lex
        when "extends"
          @extends = parse_type
        when "implements"
          parse_implements
        when '{'
          break
        else
          raise "Expected extends, implements or { but got #{token}"
        end
      end

      parse_fields_and_methods
    end

    def parse_fields_and_methods
      loop do
        forall = name = type = visibility = nil
        variadic = static = _abstract = false
        args = [] of String
        throws = [] of String

        if peek == "static" && peek(2) == '{'
          return
        end

        loop do
          case token = peek
          when "public", "protected", "private"
            visibility = lex.to_s
          when "static"
            skip
            static = true
          when "abstract"
            skip
            _abstract = true
          when "synchronized", "final", "native"
            skip
          else
            break
          end
        end

        if peek == '<'
          skip
          forall = parse_type(generic: true)
        end

        case peek(2)
        when '('
          name = lex.to_s
        else
          type = parse_type
          name = lex.to_s

          if peek == ';'
            skip
            descriptor = parse_descriptor
            fields << Field.new(visibility, static, type, name, descriptor)
            next
          end
        end

        expect '('
        parse_types(args, ')')

        if args.last?.try(&.ends_with?("..."))
          args << args.pop[0...-3]
          variadic = true
        end

        expect ')'

        if peek == "throws"
          skip
          parse_types(throws, ';')
        end

        expect ';'
        descriptor = parse_descriptor
        methods << Method.new(visibility, _abstract, static, forall, type, name, args, variadic, throws, descriptor)

        return if peek == '}'
      end
    end

    private def parse_descriptor
      expect "descriptor"
      expect ':'
      lexer.next_descriptor
    end

    private def parse_implements
      loop do
        implements << parse_type
        case peek
        when ','
          skip
        when '{', "extends"
          break
        end
      end
    end

    private def parse_types(types, ending)
      loop do
        type = parse_type
        types << type unless type.empty?
        case peek
        when ','
          skip
        when ending
          return
        end
      end
    end

    private def parse_type(generic = false)
      String.build do |str|
        parse_type(str, generic ? 1 : 0)
      end
    end

    # TODO: wildcards
    private def parse_type(str : String::Builder, nested = 0)
      case peek
      when "extends"
        until lex == '>'
          # skip
        end
      when String
        str << lex.to_s
        if peek == '<' || (nested > 0 && [',', '>', "extends"].includes?(peek))
          parse_type(str, nested + 1)
        end
      when '<'
        skip
        str << '<'
        parse_type(str, nested)
        str << '>'
      when ','
        skip
        str << ", "
        parse_type(str, nested)
      when '>'
        skip
      end
    end

    private def expect(keyword)
      if (token = lex) == keyword
        return token
      end
      raise "ERROR: expected #{keyword} (#{keyword.class.name}) but got #{token} (#{token.class.name})"
    end

    private def lex
      token = @buffer.shift? || lexer.next
      #p [:lex, token]
      token
    end

    private def skip : Nil
      token = @buffer.shift? || lexer.next
      #p [:skip, token]
    end

    private def peek
      if token = @buffer.first?
        token
      else
        if token = lexer.next
          @buffer << token
        end
        token
      end
    end

    private def peek(n)
      if @buffer.size < n
        (n - @buffer.size).times do
          if token = lexer.next
            @buffer << token
          end
        end
      end
      @buffer[n - 1]
    end
  end
end
