module Plato
  class Manifest
    include Enumerable

    attr_reader :contents
    alias to_h    contents
    alias to_hash contents

    def initialize(contents = nil)
      @contents =
        if contents.nil?
          {}
        elsif contents.respond_to? :to_hash
          contents.to_hash
        else
          raise ArgumentError, "invalid contents"
        end
    end

    def save_to(path)
      Repo.new(path).set_all(contents)
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
    def map
      new_contents =
        @contents.inject({}) do |hash, (path, data)|
          new_path_data = yield(path, data)
          new_path_data ? hash.update(new_path_data) : hash
        end

      self.class.new(new_contents)
    end

    def each(&block)
      contents.each(&block)
    end
  end
end
