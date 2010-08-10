require 'yaml'
require 'fileutils'

module Plato
  class Repo
    attr_reader :root, :codec

    CODEC_MAP = {}

    def initialize(root, codec = nil)
      unless root == File.expand_path(root)
        raise ArgumentError, "root is not an absolute path"
      end

      @codec = CODEC_MAP[codec] || StringCodec
      @root = root.sub(/\/+\Z/, '') #remove trailing slash(es)
    end

    def load(path)
      path = expanded_path(path)
      if File.exist? path
        @codec.read(path)
      else
        raise Filestore::NotFound
      end
    end

    def save(path, data)
      path = expanded_path(path)
      FileUtils.mkdir_p(File.dirname(path))
      @codec.write(path, data)
    end

    def destroy(path)
      File.unlink expanded_path(path)

      until (path = File.dirname(path)) == '.'
        expanded = expanded_path(path)

        if Dir[File.join(expanded, '*')].empty?
          File.unlink expanded
        else
          return
        end
      end
    end

    def all
      paths = Dir[File.join(root, '**/*')].select {|e| File.file? e }

      if block_given?
        paths = paths.select {|p| yield relative_path(p) }
      end

      paths.inject({}) do |hash, path|
        hash.update relative_path(path) => load(path)
      end
    end

    private

    def expanded_path(path)
      File.expand_path(path, root)
    end

    def relative_path(path)
      path.sub(/\A#{Regexp.escape(root)}\//, '').tap do |relative|
        raise ArgumentError, "path must subpath of root" if relative == path
      end
    end

    module RefCodec
      extend self

      def write(path, ref)
        FileUtils.cp(ref, path)
      end

      def read(ref)
        ref
      end
    end
    CODEC_MAP[:refs] = RefCodec

    module StringCodec
      extend self

      def write(path, data)
        File.open(path, 'w') {|f| f.write data }
      end

      def read(path)
        File.read(path)
      end
    end
    CODEC_MAP[:string] = StringCodec

    module TemplateCodec
      extend self

      def read(path)
        if template_class = Tilt[path]
          template_class.new(path)
        else
          path
        end
      end

      def write(path, data)
        raise "Templates cannot be directly written"
      end
    end
    CODEC_MAP[:template] = TemplateCodec

    module HashCodec
      extend StringCodec
      extend self

      def write(path, hash)
        hash = stringify_keys(hash)
        body = hash.delete('body')

        data = [].tap do |buffer|
          buffer << hash.map do |key, value|
            "#{header_for(key)}: #{Sanitize.header(value)}"
          end.join("\n")

          buffer << "\n\n" << Sanitize.body(body) if body
          buffer << "\n" unless buffer.last =~ /\n\Z/
        end.join

        super(path, data)
      end

      def read(path)
        string = super

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
    end
    CODEC_MAP[:hash] = HashCodec

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
