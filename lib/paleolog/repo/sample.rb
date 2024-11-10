# frozen_string_literal: true

module Paleolog
  module Repo
    class Sample
      class << self
        include CommonQueries

        def all_for_section(section_id)
          ds.where(section_id: section_id).all.map do |result|
            Paleolog::Sample.new(**result)
          end
        end

        def section_max_rank(section_id)
          ds.where(section_id: section_id).max(:rank)
        end

        def find_for_project(id, project_id)
          result = ds.where(Sequel[:samples][:id] => id, Sequel[:projects][:id] => project_id)
                     .join(:sections, Sequel[:sections][:id] => :section_id)
                     .join(:projects, Sequel[:projects][:id] => :project_id)
                     .select_all(:samples)
                     .first
          result ? Paleolog::Sample.new(**result) : nil
        end

        def find_for_section(id, section_id)
          result = ds.where(section_id: section_id, id: id).first
          result ? Paleolog::Sample.new(**result) : nil
        end

        def similar_name_exists?(name, section_id: nil, exclude_id: nil)
          scope =
            if section_id
              ds.where(section_id: section_id)
            elsif exclude_id
              ds.where(section_id: ds.where(id: exclude_id).select(:section_id))
            else
              ds
            end
          alike_name_exists?(name, exclude_id ? scope.exclude(id: exclude_id) : scope)
        end

        def name_exists_within_same_section?(name, sample_id:)
          alike_name_exists?(
            name,
            ds.exclude(id: sample_id).where(section_id: ds.where(id: sample_id).select(:section_id))
          )
        end

        def rank_exists_within_section?(rank, section_id)
          ds.where(rank: rank, section_id: section_id).limit(1).count.positive?
        end

        def entity_class
          Paleolog::Sample
        end

        def ds
          Config.db[:samples]
        end
      end
    end
  end
end
