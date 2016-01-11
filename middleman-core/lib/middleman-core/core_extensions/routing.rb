# Routing extension
module Middleman
  module CoreExtensions
    class Routing < Extension
      # This should always run late, but not as late as :directory_indexes,
      # so it can add metadata to any pages generated by other extensions
      self.resource_list_manipulator_priority = 10

      # Expose the `page` method to config.
      expose_to_config :page

      def initialize(app, options_hash={}, &block)
        super

        @page_configs = Set.new
      end

      # @return Array<Middleman::Sitemap::Resource>
      Contract ResourceList => ResourceList
      def manipulate_resource_list(resources)
        resources.each do |resource|
          @page_configs.each do |p|
            resource.add_metadata(p[:metadata]) if Middleman::Util.path_match(p[:path], "/#{resource.path}")
          end
        end
      end

      PageDescriptor = Struct.new(:path, :metadata)

      # The page method allows options to be set for a given source path, regex, or glob.
      # Options that may be set include layout, locals, andx ignore.
      #
      # @example
      #   page '/about.html', layout: false
      # @example
      #   page '/index.html', layout: :homepage_layout
      # @example
      #   page '/foo.html', locals: { foo: 'bar' }
      #
      # @param [String, Regexp] path A source path, or a Regexp/glob that can match multiple resources.
      # @params [Hash] opts Options to apply to all matching resources. Undocumented options are passed on as page metadata to be used by extensions.
      # @option opts [Symbol, Boolean, String] layout The layout name to use (e.g. `:article`) or `false` to disable layout.
      # @option opts [Boolean] directory_indexes Whether or not the `:directory_indexes` extension applies to these paths.
      # @option opts [Hash] locals Local variables for the template. These will be available when the template renders.
      # @option opts [Hash] data Extra metadata to add to the page. This is the same as frontmatter, though frontmatter will take precedence over metadata defined here. Available via {Resource#data}.
      # @return [void]
      Contract Or[String, Regexp], Hash => Any
      def page(path, opts={})
        options = opts.dup

        # Default layout
        metadata = {
          options: options,
          locals: options.delete(:locals) || {},
          page: options.delete(:data) || {}
        }

        if path.is_a?(String) && !path.include?('*')
          # Normalize path
          path = Middleman::Util.normalize_path(path)
          if path.end_with?('/') || app.files.by_type(:source).watchers.any? { |w| (w.directory + Pathname(path)).directory? }
            path = File.join(path, @app.config[:index_file])
          end
        end

        path = '/' + Util.strip_leading_slash(path) if path.is_a?(String)

        @page_configs << PageDescriptor.new(path, metadata)
      end
    end
  end
end
