module Plato
  class PathTemplate
    attr_reader :template, :keys

    def initialize(string)
      @template = string
      compile!
    end

    def materialize(attributes)
      values = attributes.values_at(*keys).compact
      unless values.length == keys.length
        raise ArgumentError, "missing required values for path materialization (#{keys.join(', ')})"
      end

      @materializer.call(values)
    end

    def parse(path)
      match = path.match(@parser)
      return nil unless match

      match = match.to_a
      match.shift

      Hash[*keys.zip(match).flatten]
    end

    private

    # basically lifted from sinatra

    SCANNER = /(:\w+(?:\\\*)?)/

    def compile!
      @keys = []

      pattern = Regexp.escape(@template).gsub SCANNER do |match|
        case match
        when /\\\*$/
          keys << match[1..-3]
          "(.*?)"
        else
          keys << match[1..-1]
          "([^/?&#]+)"
        end
      end

      @parser = /\A#{pattern}\Z/

      interpolation = @template.gsub('#', '\\#').gsub(SCANNER, '#{vals.shift}')

      @materializer = eval(%{proc {|vals| "#{interpolation}" } })
    end
  end
end
