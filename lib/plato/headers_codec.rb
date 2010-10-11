module Plato
  module HeadersCodec
    extend self

    def deflate(hash)
      hash = stringify_keys(hash)
      body = hash.delete('body')

      [].tap do |buffer|
        buffer << hash.map do |key, value|
          "#{header_for(key)}: #{Sanitize.header(value)}"
        end.join("\n")

        buffer << "\n\n" << Sanitize.body(body) if body
        buffer << "\n" unless buffer.last =~ /\n\Z/
      end
    end

    def inflate(string)
      {}.tap do |result|
        headers, body = string.split(/\n\n/, 2)

        headers.split("\n").each do |line|
          header, val = line.split(/:\s*/, 2)

          result.update hash_key_for(header) => deserialize_value(val)
        end

        result['body'] = body.chomp if body
      end
    end

    private

    def stringify_keys(hash)
      hash.inject({}) {|h, (k, v)| h.update k.to_s => v }
    end

    def header_for(attr)
      attr.to_s.gsub('_', ' ').gsub(/\b([a-z])/) {|m| m.capitalize }
    end

    def hash_key_for(header)
      header.gsub(/\s+/, '_').downcase.to_s
    end

    def deserialize_value(val)
      YAML.load(val) rescue val
    end

    module Sanitize
      extend self

      def header(header_val)
        header_val.gsub(/(\r|\n)/) {|m| {"\r" => '\r', "\n" => '\n'}[m] }
      end

      def path_elem(elem)
        elem.to_s.gsub(/\s+/, '_').gsub(/[^a-zA-Z0-9_-]/,'')
      end

      def body(body)
        body # do we really need to do anything here?
      end

      def method_missing(method, value)
        warn "Warning: not sanitizing #{method}."
        value.to_s
      end

      private

      def warn(warning)
        $stderr.puts warning
      end
    end
  end
end
