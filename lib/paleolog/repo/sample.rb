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

        def name_exists_within_section?(name, section_id)
          ds.where(section_id: section_id).where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
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
