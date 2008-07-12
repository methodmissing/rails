module ActionView #:nodoc:
  class Template
    extend TemplateHandlers
    include Renderable

    attr_accessor :filename, :load_path, :base_path, :name, :format, :extension
    delegate :to_s, :to => :path

    def initialize(template_path, load_paths = [])
      template_path = template_path.dup
      @base_path, @name, @format, @extension = split(template_path)
      @base_path.to_s.gsub!(/\/$/, '') # Push to split method
      @load_path, @filename = find_full_path(template_path, load_paths)

      # Extend with partial super powers
      extend RenderablePartial if @name =~ /^_/
    end

    def freeze
      # Eager load memoized methods
      format_and_extension
      path
      path_without_extension
      path_without_format_and_extension
      source
      method_segment

      # Eager load memoized methods from Renderable
      handler
      compiled_source

      instance_variables.each { |ivar| ivar.freeze }

      super
    end

    def format_and_extension
      @format_and_extension ||= (extensions = [format, extension].compact.join(".")).blank? ? nil : extensions
    end

    def path
      @path ||= [base_path, [name, format, extension].compact.join('.')].compact.join('/')
    end

    def path_without_extension
      @path_without_extension ||= [base_path, [name, format].compact.join('.')].compact.join('/')
    end

    def path_without_format_and_extension
      @path_without_format_and_extension ||= [base_path, name].compact.join('/')
    end

    def source
      @source ||= File.read(@filename)
    end

    def method_segment
      unless @method_segment
        segment = File.expand_path(@filename)
        segment.sub!(/^#{Regexp.escape(File.expand_path(RAILS_ROOT))}/, '') if defined?(RAILS_ROOT)
        segment.gsub!(/([^a-zA-Z0-9_])/) { $1.ord }
        @method_segment = segment
      end

      @method_segment
    end

    def render_template(view, local_assigns = {})
      render(view, local_assigns)
    rescue Exception => e
      raise e unless filename
      if TemplateError === e
        e.sub_template_of(filename)
        raise e
      else
        raise TemplateError.new(self, view.assigns, e)
      end
    end

    private
      def valid_extension?(extension)
        Template.template_handler_extensions.include?(extension)
      end

      def find_full_path(path, load_paths)
        load_paths = Array(load_paths) + [nil]
        load_paths.each do |load_path|
          file = [load_path, path].compact.join('/')
          return load_path, file if File.exist?(file)
        end
        raise MissingTemplate.new(load_paths, path)
      end

      # Returns file split into an array
      #   [base_path, name, format, extension]
      def split(file)
        if m = file.match(/^(.*\/)?([^\.]+)\.?(\w+)?\.?(\w+)?\.?(\w+)?$/)
          if m[5] # Mulipart formats
            [m[1], m[2], "#{m[3]}.#{m[4]}", m[5]]
          elsif m[4] # Single format
            [m[1], m[2], m[3], m[4]]
          else
            if valid_extension?(m[3]) # No format
              [m[1], m[2], nil, m[3]]
            else # No extension
              [m[1], m[2], m[3], nil]
            end
          end
        end
      end
  end
end
