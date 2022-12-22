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

        def with_participations
          lambda { |project|
            Paleolog::Repo::ResearchParticipation.all_for_project(project.id).each do |participation|
              project.research_participations << participation
            end
          }
        end

        def find(id, *options)
          Paleolog::Project.new(**ds.where(id: id).first) do |project|
            options.each { |opt| opt.call(project) }
          end
        end

        def name_exists?(name)
          ds.where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
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
