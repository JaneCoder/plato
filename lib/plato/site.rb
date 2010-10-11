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
    end

    def generate!
      RenderContext.load_view_helpers(File.join(template_path, 'view_helpers.rb'))
      [ resources.save_to(cache_path),
        template_resources.save_to(cache_path),
        rendered_templates.save_to(cache_path),
        rendered_content.save_to(cache_path)
      ].each do |ps|
        puts ps.map{|s| " » #{File.join(cache_path,s)}" }
      end
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

    def config
      @config ||= Config.read(ConfigDSL, File.read(config_path))
    end

    def templates
      return @templates if @templates

      manifest = Manifest.new template_path, {
        :codec => :template,
        :filter => lambda {|p| p !~ /\A(config\.rb|view_helpers\.rb)/ }
      }

      path_parser = PathTemplate.new(":name*.:format.:engine")
      sass_parser = PathTemplate.new(":name*.sass")

      @template_resources = Manifest.new({}, :refs)
      @templates = manifest.map do |path, template|
        if template.is_a? String
          # could not find a template engine, assume we're a raw resource
          @template_resources[path] = template
          nil
        else
          if match = path_parser.parse(path)
            name, format = match.values_at("name", "format")
            { "#{name}.#{format}" => Template.new(template, format) }
          else name = sass_parser.parse(path).values_at("name")
            { "#{name}.css" => Template.new(template, 'css') }
          end
        end
      end
    end

    def content
      return @content if @content

      @content = config["content_categories"]
      categories = @content.values
      content_manifests = @content.keys.map do |c|
        Manifest.new(File.join(content_path, c), :hash)
      end

      content_manifests.each do |manifest|
        manifest.each do |path, content_data|
          if category = categories.find {|c| c.match path }
            data = category.match(path).merge(content_data)

            category.documents << Document.new(category, data)
          end
        end
      end

      @content
    end

    def template_resources
      templates unless @templates
      @template_resources
    end

    def resources
      @resources ||= Manifest.new(resources_path, :refs)
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
      templates.map(:string) do |path, template|
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
