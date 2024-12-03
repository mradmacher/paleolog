# frozen_string_literal: true

module Paleolog
  module Repository
    class Species < Operation::Base
      SearchParams = Params.define.(
        group_id: Params.optional.(Params.blank_to_nil_or.(Params::IdRules)),
        project_id: Params.optional.(Params.blank_to_nil_or.(Params::IdRules)),
        name: Params.optional.(Params.blank_to_nil_or.(Params::NameRules)),
        verified: Params.optional.(Params.blank_to_nil_or.(Params.bool.(Params.any))),
      )

      FindParams = Params.define.(
        id: Params.required.(Params::IdRules),
      )

      CreateParams = Params.define.(
        name: Params.required.(Params::NameRules),
        group_id: Params.required.(Params::IdRules),
        description: Params.optional.(Params::DescriptionRules),
        environmental_preferences: Params.optional.(Params::DescriptionRules),
        verified: Params.optional.(Params.bool.(Params.any)),
      )

      UpdateParams = Params.define.(
        id: Params.required.(Params::IdRules),
        name: Params.optional.(Params::NameRules),
        group_id: Params.optional.(Params::IdRules),
        description: Params.optional.(Params::DescriptionRules),
        environmental_preferences: Params.optional.(Params::DescriptionRules),
        verified: Params.optional.(Params.bool.(Params.any)),
      )

      AddFeatureParams = Params.define.(
        species_id: Params.required.(Params::IdRules),
        choice_id: Params.required.(Params::IdRules),
      )

      AddImageParams = Params.define.(
        species_id: Params.required.(Params::IdRules),
        image_file_name: Params.required.(Params::NameRules),
      )

      def find(raw_params)
        authenticate
          .and_then { parameterize(raw_params, FindParams) }
          .and_then { authorize(_1, can_view(Paleolog::Species, :id)) }
          .and_then { carefully(_1, FindSpecies.(db)) }
      end

      def search(raw_params)
        authenticate
          .and_then { parameterize(raw_params, SearchParams) }
          .and_then { carefully(_1, search_species) }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CreateParams) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, create_species) }
      end

      def update(params)
        authenticate
          .and_then { parameterize(params, UpdateParams) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, update_species) }
      end

      def add_feature(params)
        authenticate
          .and_then { parameterize(params, AddFeatureParams) }
          .and_then { carefully(_1, CreateFeature.(db)) }
      end

      def add_image(params)
        authenticate
          .and_then { parameterize(params, AddImageParams) }
          .and_then { carefully(_1, CreateImage.(db)) }
      end

      private

      FindFeature = lambda do |db, params|
        result = db[:features].where(id: params[:id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Feature.new(**result)
      end.curry

      CreateFeature = lambda do |db, params|
        id = db[:features].insert(**params)

        FindFeature.(db, id: id)
      end.curry

      FindImage = lambda do |db, params|
        result = db[:images].where(species_id: params[:id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Image.new(**result)
      end

      CreateImage = lambda do |db, params|
        id = db[:images].insert(**params)

        FindImage.(db, id: id)
      end.curry

      FindSpecies = lambda do |db, params|
        result = db[:species].where(id: params[:id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Species.new(**result) do |species|
          WithGroup.(db, species)
          WithFeatures.(db, species)
          WithImages.(db, species)
        end
      end.curry

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

      def search_species
        lambda do |params|
          groups = db[:groups].all.map { Paleolog::Group.new(**_1) }
          search_query(params).all.map do |result|
            Paleolog::Species.new(**result) do |species|
              species.group = groups.detect { |group| group.id == species.group_id }
            end
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

      def create_species
        lambda do |params|
          species_id = db[:species].insert(timestamps_for_create.merge(**params))
          FindSpecies.(db, id: species_id)
        end
      end

      def update_species
        lambda do |params|
          db[:species].where(id: params[:id]).update(timestamps_for_update.merge(**params))
          FindSpecies.(db, id: params[:id])
        end
      end

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          { name: Operation::TAKEN } if name_exists?(db[:species], params, scope: :group_id)
        end
      end
    end
  end
end
