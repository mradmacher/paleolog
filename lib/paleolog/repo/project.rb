# frozen_string_literal: true

module Paleolog
  module Repo
    class Project
      class << self
        include CommonQueries

        def with_countings
          lambda { |project|
            Paleolog::Repo::Counting.all_for_project(project.id).each do |counting|
              project.countings << counting
            end
          }
        end

        def with_sections
          lambda { |project|
            Paleolog::Repo::Section.all_for_project(project.id).each do |section|
              project.sections << section
            end
          }
        end

        def with_researchers
          lambda { |project|
            Paleolog::Repo::Researcher.all_for_project(project.id).each do |researcher|
              project.researchers << researcher
            end
          }
        end

        def find(id, *options)
          result = ds.where(id: id).first
          return nil unless result

          Paleolog::Project.new(**result) do |project|
            options.each { |opt| opt.call(project) }
          end
        end

        def similar_name_exists?(name, exclude_id: nil)
          (exclude_id ? ds.exclude(id: exclude_id) : ds)
            .where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
        end

        def entity_class
          Paleolog::Project
        end

        def ds
          Config.db[:projects]
        end
      end
    end
  end
end
