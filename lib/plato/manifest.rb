module Plato
  class Manifest
    include Enumerable

    attr_reader :contents, :codec

    def initialize(contents = nil, opts = {})
      opts = { :codec => opts } unless opts.is_a? Hash
      @codec = opts[:codec]

      @contents =
        if contents.nil?
          {}
        elsif contents.is_a? Hash
          contents
        elsif contents.is_a? String
          Repo.new(contents, @codec).all &opts[:filter]
        else
          raise ArgumentError, "invalid contents"
        end
    end

    def save_to(path, codec = nil)
      repo = Repo.new(path, codec || self.codec)
      @contents.each {|path, hash| repo.save(path, hash) }
    end

    def [](key)
      contents[key]
    end

    def []=(key, value)
      contents[key] = value
    end
    alias store []=

    # if given a block, block should return a hash of the new path and
    # new data, or nil if the file should be skipped
    def map(new_codec = nil)
      new_contents =
        if block_given?
          @contents.inject({}) do |hash, (path, data)|
            new_path_data = yield(path, data)
            new_path_data ? hash.update(new_path_data) : hash
          end
        else
          @contents.dup
        end

      self.class.new(new_contents, new_codec || self.codec)
    end

    def each(&block)
      contents.each(&block)
    end
  end
end
