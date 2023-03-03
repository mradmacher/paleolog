# frozen_string_literal: true

module Paleolog
  module Repo
    class Section
      class << self
        include CommonQueries

        def find(id)
          Paleolog::Section.new(**ds.where(id: id).first).tap do |section|
            Paleolog::Repo::Sample.all_for_section(section.id).each do |sample|
              section.samples << sample
            end
          end
        end

        def all_for_project(project_id)
          ds.where(project_id: project_id).all.map do |result|
            Paleolog::Section.new(**result)
          end
        end

        def find_for_project(id, project_id)
          result = ds.where(project_id: project_id, id: id).first
          return nil unless result

          Paleolog::Section.new(**result) do |section|
            Paleolog::Repo::Sample.all_for_section(section.id).each do |sample|
              section.samples << sample
            end
          end
        end

        def name_exists_within_project?(name, project_id)
          ds.where(project_id: project_id).where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
        end

        def name_exists_within_same_project?(name, section_id:)
          ds.exclude(id: section_id)
            .where(project_id: ds.where(id: section_id).select(:project_id))
            .where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
        end

        def entity_class
          Paleolog::Section
        end

        def ds
          Config.db[:sections]
        end
      end
    end
  end
end
