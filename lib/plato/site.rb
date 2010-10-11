module Plato
  class Site
    attr_reader :base_url
    attr_reader :root
    attr_reader :template_path, :config_path, :content_path, :resources_path, :cache_path

    def initialize(base_url, template = 'template', cache = 'cache', root = '.')
      @base_url = base_url
      @root     = File.expand_path(root)

      @cache_path     = File.expand_path(cache, @root)
      @template_path  = detect_zip_path File.expand_path(template, @root)

      @config_path    = File.join(@template_path, 'config.rb')
      @content_path   = File.join(@root)
      @resources_path = File.join(@root, "resources")

      RenderContext.load_view_helpers(File.join(@template_path, 'view_helpers.rb'))
    end

    def generate!
      [ ["resources",          resources],
        ["template resources", template_resources],
        ["rendered templates", rendered_templates],
        ["rendered content",   rendered_content]
      ].each do |(name, manifest)|
        puts "## #{name}:"
        manifest.save_to(cache_path)
        manifest.to_h.keys.map{|p| File.join cache_path, p }.each do |path|
          puts "    #{path}"
        end
      end
    end

    def config
      @config ||= Config.read(ConfigDSL, File.read(config_path))
    end

    def templates
      initialize_templates! unless @templates
      @templates
    end

    def template_resources
      initialize_templates! unless @templates
      @template_resources
    end    

    def content
      return @content if @content

      @content = config["content_categories"]
      categories = @content.values
      content_repos = @content.keys.map do |c|
        Repo.new(File.join(content_path, c))
      end

      content_repos.each do |repo|
        repo.each do |path, file|
          if category = categories.find {|c| c.match path }
            data = category.match(path).merge(
              HeadersCodec.inflate(file.read)
            )

            category.documents << Document.new(category, data)
          end
        end
      end

      @content
    end

    def resources
      @resources ||= Manifest.new(Repo.new(resources_path))
    end

    DETECT_EXT = /(?:(.*)\/)?([^\/]+)\.([^.]+)\Z/
    def detect_zip_path(path)
      path = "#{path}.zip" if !File.exist? path and File.exist? "#{path}.zip"

      if File.exist? path and !File.directory? path and path.match(DETECT_EXT)
        dir, base, ext = path.match(DETECT_EXT).values_at(1,2,3)

        [dir, "#{base}.#{ext}!", base].compact.join("/")
      else
        path
      end
    end

    def initialize_templates!
      path_parser = PathTemplate.new(":name*.:format.:engine")
      sass_parser = PathTemplate.new(":name*.sass")

      @template_resources = Manifest.new
      @templates = {}

      Repo.new(template_path).each do |path, file|
        next if path =~ /\A(config\.rb|view_helpers\.rb)/

        if tilt_class = Tilt[path]
          tilt = tilt_class.new(File.join(template_path, path))

          if match = path_parser.parse(path)
            name, format = match.values_at("name", "format")
            @templates["#{name}.#{format}"] = Template.new(tilt, format)

          else name = sass_parser.parse(path).values_at("name")
            @templates["#{name}.css"] = Template.new(tilt, 'css')
          end
        else
          # could not find a template engine, assume we're a raw resource
          @template_resources[path] = file
          nil
        end
      end
    end
    
    # helpers

    Template = Struct.new(:renderer, :format)

    class Template
      def method_missing(m, *a, &b); renderer.send(m, *a, &b)  end
    end

    def render(template, format, document)
      RenderContext.new(self, document).render_with_layout(template, format)
    end

    def rendered_templates
      Manifest.new(templates).map do |path, template|
        if path !~ /\A_/
          { path => render(template, template.format, nil) }
        end
      end
    end

    def rendered_content
      rendered = content.values.inject({}) do |hash, category|
        if template = templates["_#{category.name}.html"]
          category.documents.each do |document|
            hash[document.path] = render(template, "html", document)
          end
        end
        hash
      end

      Manifest.new(rendered)
    end
  end
end
