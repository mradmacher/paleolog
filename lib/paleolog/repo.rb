# frozen_string_literal: true

module Paleolog
  module Repo
    module CommonQueries
      def find(id)
        entity_class.new(**ds.where(id: id).first)
      end

      def create(attributes)
        find(ds.insert(create_timestamps.merge(attributes)))
      end

      def update(id, attributes)
        ds.where(id: id).update(update_timestamps.merge(attributes))
        find(id)
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
require 'paleolog/repo/research_participation'
require 'paleolog/repo/sample'
require 'paleolog/repo/section'
require 'paleolog/repo/species'
require 'paleolog/repo/user'

module Paleolog
  module Repo
    def self.save(obj)
      if obj.id.nil? || obj.id == None
        self.for(obj.class).create(obj.defined_attributes)
      else
        self.for(obj.class).update(obj.id, obj.defined_attributes)
      end
    end

    def self.find(type, id)
      self.for(type).find(id)
    end

    def self.for(type)
      if type == Paleolog::Group
        @group_repo ||= Paleolog::Repo::Group.new
      elsif type == Paleolog::Species
        @species_repo ||= Paleolog::Repo::Species.new
      elsif type == Paleolog::Field
        @field_repo ||= Paleolog::Repo::Field.new
      elsif type == Paleolog::Choice
        @choice_repo ||= Paleolog::Repo::Choice.new
      elsif type == Paleolog::Feature
        @feature_repo ||= Paleolog::Repo::Feature.new
      elsif type == Paleolog::Image
        @image_repo ||= Paleolog::Repo::Image.new
      elsif type == Paleolog::Project
        @project_repo ||= Paleolog::Repo::Project.new
      elsif type == Paleolog::Counting
        @counting_repo ||= Paleolog::Repo::Counting.new
      elsif type == Paleolog::Section
        @section_repo ||= Paleolog::Repo::Section.new
      elsif type == Paleolog::Sample
        @sample_repo ||= Paleolog::Repo::Sample.new
      elsif type == Paleolog::Occurrence
        @occurrence_repo ||= Paleolog::Repo::Occurrence.new
      elsif type == Paleolog::User
        @user_repo ||= Paleolog::Repo::User.new
      elsif type == Paleolog::ResearchParticipation
        @research_participation_repo ||= Paleolog::Repo::ResearchParticipation.new
      else
        raise 'dupa'
      end
    end
  end
end
