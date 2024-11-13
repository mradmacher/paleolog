# frozen_string_literal: true

module Paleolog
  module Repo
    module CommonQueries
      def find(id, *options)
        result = ds.where(id: id).first
        return nil unless result

        entity_class.new(**result) do |entity|
          options.each { |opt| opt.call(entity) }
        end
      end

      def delete(id)
        ds.where(id: id).delete
      end

      def create(attributes)
        ds.insert(create_timestamps.merge(attributes))
      end

      def update(id, attributes)
        ds.where(id: id).update(update_timestamps.merge(attributes)) unless attributes.empty?
        id
      end

      def all
        ds.all.map { |result| entity_class.new(**result) }
      end

      def delete_all
        ds.delete
      end

      def use_timestamps?
        true
      end

      def create_timestamps
        use_timestamps? ? { created_at: Time.now, updated_at: Time.now } : {}
      end

      def update_timestamps
        use_timestamps? ? { updated_at: Time.now } : {}
      end
    end
  end
end

require 'paleolog/repo/config'
require 'paleolog/repo/choice'
require 'paleolog/repo/counting'
require 'paleolog/repo/group'
require 'paleolog/repo/feature'
require 'paleolog/repo/field'
require 'paleolog/repo/image'
require 'paleolog/repo/occurrence'
require 'paleolog/repo/project'
require 'paleolog/repo/researcher'
require 'paleolog/repo/sample'
require 'paleolog/repo/section'
require 'paleolog/repo/species'
require 'paleolog/repo/user'

module Paleolog
  module Repo
    REPOS = {
      Paleolog::Group => Paleolog::Repo::Group,
      Paleolog::Species => Paleolog::Repo::Species,
      Paleolog::Field => Paleolog::Repo::Field,
      Paleolog::Choice => Paleolog::Repo::Choice,
      Paleolog::Feature => Paleolog::Repo::Feature,
      Paleolog::Image => Paleolog::Repo::Image,
      Paleolog::Project => Paleolog::Repo::Project,
      Paleolog::Counting => Paleolog::Repo::Counting,
      Paleolog::Section => Paleolog::Repo::Section,
      Paleolog::Sample => Paleolog::Repo::Sample,
      Paleolog::Occurrence => Paleolog::Repo::Occurrence,
      Paleolog::User => Paleolog::Repo::User,
      Paleolog::Researcher => Paleolog::Repo::Researcher,
    }.freeze

    def self.save(obj)
      if obj.id.nil?
        self.for(obj.class).create(obj.defined_attributes_with_values)
      else
        self.for(obj.class).update(obj.id, obj.defined_attributes_with_values)
      end
    end

    def self.find(type, id)
      self.for(type).find(id)
    end

    def self.delete(type, id)
      self.for(type).delete(id)
    end

    def self.delete_all(type)
      self.for(type).delete_all
    end

    def self.for(type)
      REPOS[type]
    end

    def self.with_transaction(&block)
      Config.db.transaction do
        block.call
      end
    end

    def self.db
      Config.db
    end

    def self.researchers
      Config.db[:research_participations]
    end

    def self.projects
      Config.db[:projects]
    end
  end
end
