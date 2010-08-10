module Plato
  class RenderContext
    include Tilt::CompileSite

    attr_reader :site, :document
    alias post document

    def initialize(site, document)
      @site = site
      @document = document
    end

    def template(key)
      site.templates["#{key}.html"] || site.templates[key]
    end

    def render(template, locals = {}, &block)
      template = self.template(template) if template.is_a? String
      raise ArgumentError, "template #{template.inspect} not found" unless template
      template.render(self, locals, &block)
    end

    def render_with_layout(template, format = nil, &block)
      layout = template("_layout.#{format}") if format

      if layout
        render(layout) { render(template, &block) }
      else
        render(template, &block)
      end
    end

    def render_body
      document.body(self)
    end
    alias body render_body

    def self.load_view_helpers(path)
      return if @helpers_loaded
      @helpers_loaded = true

      mod = Module.new
      mod.module_eval(File.read(path), path, 1)
      include mod.const_get(mod.constants.first)
    end

    # base set of helpers

    def url_for(doc, opts = {})
      return doc if doc.is_a? String and doc =~ /\Ahttp:\/\//
      base = opts[:absolute] ? site.base_url : '/'
      File.join(base, doc.respond_to?(:path) ? doc.path : doc.to_s)
    end

    def link_to(title, url)
      %{<a href="#{url}">#{title}</a>}
    end

    def content; site.content end

    def attribute_pairs(hash)
      hash.map {|k,v| %{#{k}="#{v}"} }.join(' ')
    end

    def css_include(url, opts = {})
      url = "#{url.gsub(/\.css\Z/, '')}.css"
      opts = opts.merge :type => "text/css", :rel => "stylesheet", :href=> url_for(url)
      %{<link #{attribute_pairs(opts)} />}
    end

    def script_include(url, opts = {})
      url = "#{url.gsub(/\.js\Z/, '')}.js"
      opts = opts.merge :src => url_for(url)
      %{<script #{attribute_pairs(opts)}></script>}
    end
  end

  class RubyTiltTemplate < Tilt::Template
    def prepare; end

    def precompiled_template(locals)
      data
    end
  end

  ::Tilt.register('rb', RubyTiltTemplate)
end
