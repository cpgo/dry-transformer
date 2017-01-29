module Transproc
  class Transformer
    # @api private
    module ClassInterface
      # Return a base Transproc::Transformer class with the
      # container configured to the passed argument.
      #
      # @example
      #
      #   class MyTransformer < Transproc::Transformer[Transproc]
      #   end
      #
      # @param [Transproc::Registry] container
      #   The container to resolve transprocs from
      #
      # @return [subclass of Transproc::Transformer]
      #
      # @api public
      def [](container)
        klass = Class.new(Transformer)
        klass.container(container)
        klass
      end

      # @api private
      def inherited(subclass)
        subclass.container(@container) if defined?(@container)
      end

      # Get or set the container to resolve transprocs from.
      #
      # @example
      #
      #   # Setter
      #   Transproc::Transformer.container(Transproc)
      #   # => Transproc
      #
      #   # Getter
      #   Transproc::Transformer.container
      #   # => Transproc
      #
      # @param [Transproc::Registry] container
      #   The container to resolve transprocs from
      #
      # @return [Transproc::Registry]
      #
      # @api private
      def container(container = ::Transproc::Undefined)
        if container == ::Transproc::Undefined
          ensure_container_presence!
          @container
        else
          @container = container
        end
      end

      # Define an anonymous transproc derived from given Transformer
      # Evaluates block with transformations and returns initialized transproc.
      # Does not mutate original Transformer
      #
      # @example
      #
      #   class MyTransformer < Transproc::Transformer[MyContainer]
      #   end
      #
      #   transproc = MyTransformer.define do
      #     map_values t(:to_string)
      #   end
      #   transproc.call(a: 1, b: 2)
      #   # => {a: '1', b: '2'}
      #
      # @yield Block allowing to define transformations. The same as class level DSL
      #
      # @return [Function] Composed transproc
      #
      # @api public
      def define(&block)
        return transproc unless block_given?

        Class.new(self).tap { |klass| klass.instance_eval(&block) }.transproc
      end
      alias build define

      # Get a transformation from the container,
      # without adding it to the transformation pipeline
      #
      # @example
      #
      #   class Stringify < Transproc::Transformer
      #     map_values t(:to_string)
      #   end
      #
      #   Stringify.new.call(a: 1, b: 2)
      #   # => {a: '1', b: '2'}
      #
      # @param [Proc, Symbol] fn
      #   A proc, a name of the module's own function, or a name of imported
      #   procedure from another module
      # @param [Object, Array] args
      #   Args to be carried by the transproc
      #
      # @return [Transproc::Function]
      #
      # @api public
      def t(fn, *args)
        container[fn, *args]
      end

      # @api private
      def method_missing(method, *args, &block)
        if container.contain?(method)
          args.push(define(&block)) if block_given?
          transformations << t(method, *args)
        else
          super
        end
      end

      # @api private
      def respond_to_missing?(method, _include_private = false)
        container.contain?(method) || super
      end

      # @api private
      def transproc
        transformations.reduce(:>>)
      end

      private

      # An array containing the transformation pipeline
      #
      # @api private
      def transformations
        @transformations ||= []
      end

      # @api private
      def ensure_container_presence!
        return if defined?(@container)
        raise ArgumentError, 'Transformer function registry is empty. '\
                             'Provide your registry via Transproc::Transformer[YourRegistry]'
      end
    end
  end
end
