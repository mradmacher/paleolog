# frozen_string_literal: true

require 'rom-repository'
require 'rom-changeset'

module Paleolog
  module Repository
    class Project < ROM::Repository[:projects]
      commands :create, update: :by_pk, delete: :by_pk

      def self.new(container = Paleolog::Repository::Config.db)
        super(container)
      end

      def clear
        projects.delete
      end

      def find(id)
        projects.by_pk(id).one!
      end

      def find_section(project, id)
        sections.combine(:samples).by_pk(id).one!
      end

      def add_section(project, attributes)
        sections.changeset(:create, attributes).associate(project).commit
      end

      def find_sample(project, id)
        samples.by_pk(id).one!
      end

      def find_counting(project, id)
        countings.combine(:group).combine(species: [:group]).by_pk(id).one!
      end

      def add_counting(project, attributes)
        countings.changeset(:create, attributes).associate(project).commit
      end

      def find_with_dependencies(id)
        projects.combine(:users).combine(:sections).combine(:countings).by_pk(id).one!
      end

      def all
        projects.combine(:research_participations).order { created_at.desc }.to_a
      end
    end
  end
end
