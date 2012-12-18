if CompassRails.rails4?
  module Sprockets
    class SassTemplate
      class_attribute :compass_load_paths
      # We override this method completely. Ideally Sprockets
      # would expose an api that would allow us to add additional
      # importers.
      def evaluate(context, locals, &block)
        # Use custom importer that knows about Sprockets Caching
        cache_store = SassCacheStore.new(context.environment)

        load_paths = context.environment.paths.map { |path| SassImporter.new(context, path) }
        load_paths.concat(compass_load_paths)

        options = {
          :filename => eval_file,
          :line => line,
          :syntax => syntax,
          :cache_store => cache_store,
          :importer => SassImporter.new(context, context.pathname),
          :load_paths => load_paths,
          :sprockets => {
            :context => context,
            :environment => context.environment
          }
        }

        ::Sass::Engine.new(data, options).render
      rescue ::Sass::SyntaxError => e
        # Annotates exception message with parse line number
        context.__LINE__ = e.sass_backtrace.first[:line]
        raise e
      end
    end
  end
else
  require 'sprockets/static_compiler'
  module Sprockets
    class StaticCompiler
      cattr_accessor :generated_sprites
      self.generated_sprites = {}
      def write_manifest_with_sprites(manifest)
        write_manifest_without_sprites(manifest.merge(self.class.generated_sprites))
      end
      alias_method_chain :write_manifest, :sprites
    end
  end
end

