require 'yaml'
require 'fileutils'

module Plato
  class FileObject
    attr_reader :path, :data

    def initialize(opts = {})
      @path = opts[:path]
      @data = opts[:data]
    end

    def data
      @data ||= (File.read(@path) if @path)
    end
    alias read data

    def write_to(to_path)
      if @data
        FileUtils.mkdir_p(File.dirname(to_path))
        File.open(to_path, 'w') {|f| f.write(@data) }
      elsif @path
        FileUtils.mkdir_p(File.dirname(to_path))
        FileUtils.cp(@path, to_path)
      else
        raise "cannot write out empty file object"
      end
    end
  end
  
  class Repo
    class NotFound < StandardError; end

    attr_reader :root

    def initialize(root)
      unless root == File.expand_path(root)
        raise ArgumentError, "root is not an absolute path"
      end

      @root = root.sub(/\/+\Z/, '') #remove trailing slash(es)
    end

    def get(path)
      path = expanded_path(path)
      raise NotFound unless File.exist? path

      FileObject.new(:path => path)
    end

    def set(path, data)
      fo = data.respond_to?(:write_to) ?
        data : FileObject.new(:data => data)

      fo.write_to(expanded_path(path))
    end

    def all
      paths = Dir[File.join(root, '**/*')].select {|e| File.file? e }

      paths.inject({}) do |hash, path|
        relative = relative_path(path)
        hash.update relative => get(relative)
      end
    end
    alias to_h    all
    alias to_hash all

    def each(&block)
      all.each(&block)
    end

    def set_all(hash)
      hash.each {|path, data| set(path, data) }
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

    private

    def expanded_path(path)
      File.expand_path(path, root)
    end

    def relative_path(path)
      path.sub(/\A#{Regexp.escape(root)}\//, '').tap do |relative|
        raise ArgumentError, "path must subpath of root" if relative == path
      end
    end
  end
end
