# frozen_string_literal: true

module Paleolog
  module Repository
    class Species < Operation::Base
      SEARCH_PARAMS = Params.define do |p|
        {
          group_id: p::OPTIONAL.(p::BLANK_TO_NIL_OR.(p::ID)),
          project_id: p::OPTIONAL.(p::BLANK_TO_NIL_OR.(p::ID)),
          name: p::OPTIONAL.(p::BLANK_TO_NIL_OR.(p::NAME)),
          verified: p::OPTIONAL.(p::BLANK_TO_NIL_OR.(p::BOOL)),
        }
      end

      FIND_PARAMS = Params.define do |p|
        {
          id: p::REQUIRED.(p::ID),
        }
      end

      CREATE_PARAMS = Params.define do |p|
        {
          name: p::REQUIRED.(p::NAME),
          group_id: p::REQUIRED.(p::ID),
          description: p::OPTIONAL.(p::DESCRIPTION),
          environmental_preferences: p::OPTIONAL.(p::DESCRIPTION),
          verified: p::OPTIONAL.(p::BOOL),
        }
      end

      UPDATE_PARAMS = Params.define do |p|
        {
          id: p::REQUIRED.(p::ID),
          name: p::OPTIONAL.(p::NAME),
          group_id: p::OPTIONAL.(p::ID),
          description: p::OPTIONAL.(p::DESCRIPTION),
          environmental_preferences: p::OPTIONAL.(p::DESCRIPTION),
          verified: p::OPTIONAL.(p::BOOL),
        }
      end

      ADD_FEATURE_PARAMS = Params.define do |p|
        {
          species_id: p::REQUIRED.(p::ID),
          choice_id: p::REQUIRED.(p::ID),
        }
      end

      ADD_IMAGE_PARAMS = Params.define do |p|
        {
          species_id: p::REQUIRED.(p::ID),
          image_file_name: p::REQUIRED.(p::NAME),
        }
      end

      def find(raw_params)
        authenticate
          .and_then { parameterize(raw_params, FIND_PARAMS) }
          .and_then { authorize(_1, can_view(Paleolog::Species, :id)) }
          .and_then { |params| carefully { find_species(params) } }
      end

      def search(raw_params)
        authenticate
          .and_then { parameterize(raw_params, SEARCH_PARAMS) }
          .and_then { |params| carefully { search_species(params) } }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CREATE_PARAMS) }
          .and_then { verify_name_uniqueness(_1, db[:species], scope: :group_id) }
          .and_then { |params| carefully { create_species(params) } }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { verify_name_uniqueness(_1, db[:species], scope: :group_id) }
          .and_then { |params| carefully { update_species(params) } }
      end

      def add_feature(raw_params)
        authenticate
          .and_then { parameterize(raw_params, ADD_FEATURE_PARAMS) }
          .and_then { |params| carefully { create_feature(params) } }
      end

      def add_image(raw_params)
        authenticate
          .and_then { parameterize(raw_params, ADD_IMAGE_PARAMS) }
          .and_then { |params| carefully { create_image(params) } }
      end

      private

      def find_feature(params)
        result = db[:features].where(id: params[:id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Feature.new(**result)
      end

      def create_feature(params)
        id = db[:features].insert(**params)

        find_feature(id: id)
      end

      def find_image(params)
        result = db[:images].where(species_id: params[:id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Image.new(**result)
      end

      def create_image(params)
        id = db[:images].insert(**params)

        find_image(id: id)
      end

      def find_species(params)
        result = db[:species].where(id: params[:id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Species.new(**result) do |species|
          WithGroup.(db, species)
          WithFeatures.(db, species)
          WithImages.(db, species)
        end
      end

      WithGroup = lambda do |db, species|
        species.group = Paleolog::Group.new(**db[:groups].where(id: species.group_id).first)
      end

      WithImages = lambda do |db, species|
        db[:images].where(species_id: species.id).all.map do |result|
          species.images << Paleolog::Image.new(**result)
        end
      end

      WithFeatures = lambda do |db, species|
        features_result = db[:features].where(species_id: species.id).all

        choice_ids = features_result.map { |f| f[:choice_id] }.uniq
        choices_result = db[:choices].where(id: choice_ids)

        field_ids = choices_result.map { |r| r[:field_id] }.uniq
        fields = db[:fields].where(id: field_ids).all.map { Paleolog::Field.new(**_1) }

        choices = choices_result.map do |choice_result|
          Paleolog::Choice.new(**choice_result) do |choice|
            choice.field = fields.detect { |f| f.id == choice.field_id }
          end
        end

        features_result.map do |r|
          species.features << Paleolog::Feature.new(**r) do |feature|
            feature.choice = choices.detect { |c| c.id == feature.choice_id }
          end
        end
      end

      def search_species(params)
        groups = db[:groups].all.map { Paleolog::Group.new(**_1) }
        search_query(params).all.map do |result|
          Paleolog::Species.new(**result) do |species|
            species.group = groups.detect { |group| group.id == species.group_id }
          end
        end
      end

      def search_query(filters = {})
        query = db[:species]
        query = query.where(group_id: filters[:group_id]) if filters[:group_id]
        query = query.where(Sequel.ilike(Sequel[:species][:name], "%#{filters[:name]}%")) if filters[:name]
        query = query.where(verified: true) if filters[:verified]
        query = project_filter(query, filters[:project_id]) if filters[:project_id]
        query
      end

      def project_filter(query, project_id)
        occurrences_refs =
          db[:occurrences]
          .where(Sequel[:sections][:project_id] => project_id)
          .join(:samples, Sequel[:samples][:id] => :sample_id)
          .join(:sections, Sequel[:sections][:id] => :section_id)
        query.where(id: occurrences_refs.select(:species_id))
      end

      def create_species(params)
        species_id = db[:species].insert(timestamps_for_create.merge(**params))
        find_species(id: species_id)
      end

      def update_species(params)
        db[:species].where(id: params[:id]).update(timestamps_for_update.merge(**params))
        find_species(id: params[:id])
      end
    end
  end
end
