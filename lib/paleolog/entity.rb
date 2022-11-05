module Paleolog
  module Entity
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def available_attributes
        @available_attributes || []
      end

      def available_belongs_tos
        @available_belongs_tos || []
      end

      def available_has_manys
        @available_has_manys || []
      end

      def schema
        yield

        define_method(:initialize) do |**args, &block|
          assign_values(args)
          assign_belongs_to(args)
          assign_has_many
          block&.call(self)
          defined_attributes
          freeze
        end

        define_method(:==) do |other|
          cmp_with(other)
        end
      end

      def attributes(*list)
        @available_attributes = []
        list.each do |attr|
          @available_attributes << attr
          define_method(attr) do
            instance_variable_get("@#{attr}")
          end
        end
      end

      def belongs_to(*list)
        @available_belongs_tos = []
        list.each do |attr|
          @available_belongs_tos << attr
          define_method(attr) do
            instance_variable_get("@#{attr}")
          end
          define_method("#{attr}=") do |obj|
            instance_variable_set("@#{attr}_id", obj&.id)
            instance_variable_set("@#{attr}", obj)
          end
        end
      end

      # rubocop:disable Naming/PredicateName
      def has_many(*list)
        @available_has_manys = []
        list.each do |attr|
          @available_has_manys << attr
          define_method(attr) do
            instance_variable_get("@#{attr}")
          end
          # define_method("add_#{attr}") do |obj|
          #  instance_variable_get("@#{attr}") << obj
          # end
        end
      end
      # rubocop:enable Naming/PredicateName
    end

    def defined_attributes
      {}.tap do |h|
        self.class.available_attributes.each do |attr|
          value = instance_variable_get("@#{attr}")
          h[attr.to_sym] = value unless value.is_a?(Option::None)
        end
      end
    end

    private

    def assign_values(args)
      self.class.available_attributes.each do |attr|
        instance_variable_set("@#{attr}", args.key?(attr) ? args[attr] : Option.None)
      end
    end

    def assign_belongs_to(args)
      self.class.available_belongs_tos.each do |attr|
        if args.key?(attr)
          send("#{attr}=", args[attr])
        else
          instance_variable_set("@#{attr}", Option.None)
        end
      end
    end

    def assign_has_many
      self.class.available_has_manys.each do |attr|
        instance_variable_set("@#{attr}", [])
      end
    end

    def cmp_with(other)
      instance_of?(other.class) && (
        !id.nil? && !other.id.nil? && id == other.id ||
        defined_attributes == other.defined_attributes
      )
    end
  end
end
