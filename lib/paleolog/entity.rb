# frozen_string_literal: true

class None
  def self.defined?
    false
  end

  def self.nil?
    true
  end
end

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
          self.class.available_attributes.each do |attr|
            instance_variable_set("@#{attr}", args.key?(attr) ? args[attr] : None)
          end
          self.class.available_belongs_tos.each do |attr|
            if args.key?(attr)
              self.send("#{attr}=", args[attr])
            else
              instance_variable_set("@#{attr}", None)
            end
          end
          self.class.available_has_manys.each do |attr|
            instance_variable_set("@#{attr}", [])
          end
          block.call(self) if block
          defined_attributes
          freeze
        end

        define_method(:==) do |other|
          self.class == other.class && (
            !self.id.nil? && !other.id.nil? && self.id == other.id ||
            self.defined_attributes == other.defined_attributes
          )
        end
      end

      def attributes(*list)
        @available_attributes = []
        list.each do |attr|
          @available_attributes << attr
          define_method(attr) {
            instance_variable_get("@#{attr}")
          }
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

      def has_many(*list)
        @available_has_manys = []
        list.each do |attr|
          @available_has_manys << attr
          define_method(attr) do
            instance_variable_get("@#{attr}")
          end
          #define_method("add_#{attr}") do |obj|
          #  instance_variable_get("@#{attr}") << obj
          #end
        end
      end
    end

    def defined_attributes
      @defined_attributes ||= {}.tap do |h|
        self.class.available_attributes.each do |attr|
          value = instance_variable_get("@#{attr}")
          h[attr.to_sym] = value unless value == None
        end
      end
    end
  end
end
