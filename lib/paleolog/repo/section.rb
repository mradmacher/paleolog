# frozen_string_literal: true

module Paleolog
  module Repo
    class Section
      class << self
        include CommonQueries

        def with_samples
          lambda { |section|
            Paleolog::Repo::Sample.all_for_section(section.id).each do |sample|
              section.samples << sample
            end
          }
        end

        def find(id, *options)
          Paleolog::Section.new(**ds.where(id: id).first).tap do |section|
            options.each { |opt| opt.call(section) }
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

        def similar_name_exists?(name, project_id: nil, exclude_id: nil)
          scope =
            if project_id
              ds.where(project_id: project_id)
            elsif exclude_id
              ds.where(project_id: ds.where(id: exclude_id).select(:project_id))
            else
              ds
            end
          query = exclude_id ? scope.exclude(id: exclude_id) : scope
          query.where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
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
