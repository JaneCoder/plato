module Plato
  module Config
    extend self

    def read(dsl_class, string = nil, &block)
      config = dsl_class.new

      if string
        config.instance_eval(string)
      else
        block.arity == 1 ? call.block(config) : config.instance_eval(&block)
      end

      extract_ivars(config)
    end

    private

    def extract_ivars(config)
      config.instance_variables.inject({}) do |result, ivar|
        result.update(ivar.sub('@', '') => config.instance_variable_get(ivar))
      end
    end
  end

  class ConfigDSL
    # Config DSL

    def base_url(url)
      @base_url = url
    end
    alias url base_url

    def options(hash)
      @options = hash
    end

    def content(name, content_path_template, opts = {})
      @content_categories ||= {}
      @content_categories[name.to_s] =
        ContentCategory.new(name, content_path_template,
          opts[:to] || content_path_template, opts[:sort], opts[:template])
    end
  end

  class ContentCategory
    attr_reader :name, :documents, :src_parser, :dest_parser, :template

    def initialize(name, src_t, dest_t, sort, template)
      @name = name
      @documents = DocumentCollection.new(sort)
      @src_parser = PathTemplate.new(src_t)
      @dest_parser = PathTemplate.new(dest_t)
      @template = "_#{template}" if template
    end

    def match(path); src_parser.parse(path) end
    def dest_path(data); dest_parser.materialize(data) end

    def method_missing(method, *args, &block)
      documents.send(method, *args, &block)
    end
  end

end
