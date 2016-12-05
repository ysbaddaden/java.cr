module JavaP
  class Lexer
    private getter source : String
    private getter pos : Int32

    # OPTIMIZE: take an IO instead of a String
    def initialize(@source)
      @pos = 0
    end

    def next
      return if eof?
      loop do
        case peek
        when ',', '<', '>', '(', ')', '{', '}', ';', ':'
          return consume
        when '\n', '\r', .ascii_whitespace?
          skip
        when '"'
          skip
          return next_string
        else
          return next_word
        end
      end
    end

    def next_descriptor
      n = 0
      loop do
        raise "ERROR: expected descriptor but got EOF" if eof?
        if peek(n) == '\n'
          return consume(n).strip.tap { skip }
        else
          n += 1
        end
      end
    end

    private def next_string
      n = 0
      loop do
        raise "ERROR: expected \" but got EOF" if eof?
        if peek(n) == '"'
          return consume(n).tap { skip }
        else
          n += 1
        end
      end
    end

    private def next_word
      n = 0
      loop do
        case peek(n)
        when ',', '<', '>', '(', ')', '{', '}', ';', ':', '\n', '"', .ascii_whitespace?
          return consume(n)
        else
          return consume(n) if eof?
          n += 1
        end
      end
    end

    def eof?
      pos >= source.size
    end

    private def peek
      #p [:peek, source[pos]]
      source[pos]
    end

    private def peek(n)
      #p [:peek, n, source[pos + n]]
      source[pos + n]
    end

    private def consume
      #p [:consume, peek]
      peek.tap { @pos += 1 }
    end

    private def consume(n)
      #p [:consume, n, source[pos, n]]
      source[pos, n].tap { @pos += n }
    end

    private def skip(n = 1)
      #p [:skip, n]
      @pos += n
    end
  end
end
