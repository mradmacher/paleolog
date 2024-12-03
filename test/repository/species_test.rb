# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repository::Species do
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) { Paleolog::Repository::Species.new(Paleolog.db, authorizer) }
  let(:happy_operation) { happy_operation_for(Paleolog::Repository::Species, user) }
  let(:group) { happy_operation_for(Paleolog::Repository::Group, user).create(name: 'A Group').value }
  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end

  describe '#search' do
    let(:other_group) do
      happy_operation_for(Paleolog::Repository::Group, user).create(name: 'Other').value
    end
    let(:species1) do
      happy_operation.create(group_id: group.id, name: 'Odontochitina costata').value
    end
    let(:species2) do
      happy_operation.create(group_id: group.id, name: 'Cerodinium diebelii').value
    end
    let(:species3) do
      happy_operation.create(group_id: other_group.id, name: 'Acritarchs').value
    end

    before do
      species1
      species2
      species3
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.search({})

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthenticated?(result.error)

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
      end

      describe 'when verified filter provided' do
        let(:filters) { { verified: true } }

        it 'does not return not verified' do
          result = operation.search(filters)

          assert_predicate result, :success?
          assert_predicate result.value, :empty?
        end

        it 'returns only verified' do
          happy_operation_for(Paleolog::Repository::Species, user)
            .update(id: species2.id, verified: true)

          result = operation.search(filters)

          assert_predicate result, :success?
          collection = result.value

          assert_equal 1, collection.size
          assert_equal collection.first.id, species2.id
          refute_nil collection.first.group
        end
      end

      describe 'when group filter provided' do
        let(:filters) { { group_id: group.id } }

        it 'returns only species that match filter' do
          result = operation.search(filters)

          assert_predicate result, :success?

          collection = result.value

          assert_equal 2, collection.size

          assert_equal collection.map(&:id), [species1.id, species2.id]
          refute_nil collection.first.group
        end
      end

      describe 'when name filter provided' do
        let(:filters) { { name: 'costa' } }

        it 'returns only species that match filter' do
          result = operation.search(filters)

          assert_predicate result, :success?

          collection = result.value

          assert_equal 1, collection.size
          assert_equal collection.first.id, species1.id
          refute_nil collection.first.group
        end

        it 'is case insensitive' do
          result = operation.search(filters)

          assert_predicate result, :success?

          collection = result.value

          assert_equal 1, collection.size
          assert_equal collection.first.id, species1.id
        end
      end

      describe 'when name, group and verified filters provided' do
        let(:filters) { { group_id: group.id, name: 'costa', verified: false } }

        it 'returns only verified that match filter' do
          result = operation.search(filters)

          assert_predicate result, :success?

          collection = result.value

          assert_equal 1, collection.size
          assert_equal collection.first.id, species1.id
          refute_nil collection.first.group
        end
      end

      describe 'when empty filters provided' do
        let(:filters) { { group_id: '', name: '', verified: '' } }

        it 'ignores them' do
          result = operation.search(filters)

          assert_predicate result, :success?

          collection = result.value

          assert_equal 3, collection.size
        end
      end

      describe 'when project filter provided' do
        let(:project) do
          happy_operation_for(Paleolog::Repository::Project, user)
            .create(name: 'Test Project')
            .value
        end
        let(:other_project) do
          happy_operation_for(Paleolog::Repository::Project, user)
            .create(name: 'Other Test Project')
            .value
        end
        let(:filters) { { project_id: project.id } }

        it 'displays species from occurrences' do
          section = happy_operation_for(Paleolog::Repository::Section, user)
                    .create(name: 'Some section', project_id: project.id)
                    .value
          sample = happy_operation_for(Paleolog::Repository::Sample, user)
                   .create(name: 'Some sample', section_id: section.id)
                   .value
          counting = happy_operation_for(Paleolog::Repository::Counting, user)
                     .create(name: 'Some counting', project_id: project.id)
                     .value

          happy_operation_for(Paleolog::Repository::Occurrence, user)
            .create(species_id: species1.id, counting_id: counting.id, sample_id: sample.id)
            .value

          result = operation.search({ project_id: project.id })

          assert_predicate result, :success?

          collection = result.value

          assert_equal 1, collection.size
          assert_equal collection.first.id, species1.id
          refute_nil collection.first.group
        end
      end
    end
  end

  describe '#find' do
    let(:species) do
      happy_operation.create(name: 'Some Name', group_id: group.id).value
    end

    it 'returns authenticated user' do
      authorizer.expect :authenticated?, false

      result = operation.find(id: species.id)

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthenticated?(result.error)

      authorizer.verify
    end

    it 'returns authorized user' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_view?, false, [Paleolog::Species, species.id]

      result = operation.find(id: species.id)

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthorized?(result.error)

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_view?, true, [Paleolog::Species, species.id]
      end

      it 'returns species' do
        result = operation.find(id: species.id)

        assert_predicate result, :success?

        found_species = result.value

        refute_nil found_species

        refute_nil found_species.id
        assert_equal found_species.id, species.id
        assert_equal found_species.name, species.name
        assert_equal found_species.group_id, species.group_id
        refute_nil found_species.group
      end

      it 'finds species and loads all dependencies' do
        choice = nil
        happy_operation_for(Paleolog::Repository::Field, user).tap do |op|
          field = op.create(name: 'Type', group_id: group.id).value
          choice = op.add_choice(field_id: field.id, name: 'G').value
        end
        authorizer.expect :authenticated?, true
        operation.add_feature(species_id: species.id, choice_id: choice.id)
        authorizer.expect :authenticated?, true
        operation.add_image(species_id: species.id, image_file_name: 'nice_picture.jpg')
        result = operation.find(id: species.id)

        assert_predicate result, :success?

        found_species = result.value

        refute_nil found_species.group
        refute_empty found_species.features

        assert_equal 1, found_species.features.size
        refute_nil found_species.features.first.choice.field
        assert_equal 'Type', found_species.features.first.choice.field.name
        refute_empty found_species.images
        assert_equal 1, found_species.images.size
      end
    end
  end

  describe '#update' do
    let(:species) do
      happy_operation.create(name: 'Some Name', group_id: group.id).value
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.update(id: species.id, name: 'Just a Name')

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthenticated?(result.error)

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
      end

      it 'complains when group_id blank' do
        result = operation.update(id: species.id, group_id: nil)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::NON_INTEGER, result.error[:group_id]
      end

      it 'can set the same name' do
        result = operation.update(id: species.id, name: 'Some Name')

        assert_predicate result, :success?
        assert_equal 'Some Name', result.value.name
      end

      it 'does not complain when name not taken yet' do
        result = operation.update(id: species.id, name: 'Some Other Name')

        assert_predicate result, :success?
      end

      it 'complains when name is nil' do
        result = operation.update(id: species.id, name: nil)

        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.update(id: species.id, name: '  ')

        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(name: 'Some Other Name', group_id: group.id)

        assert_predicate result, :success?

        result = operation.update(id: species.id, name: 'Some Other Name')

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'allows same name for different group' do
        other_group = happy_operation_for(Paleolog::Repository::Group, user).create(name: 'Other Group').value
        result = happy_operation.create(name: 'Some Name', group_id: other_group.id)

        assert_predicate result, :success?

        result = operation.update(id: species.id, name: 'Some Other Name')

        assert_predicate result, :success?
        assert_equal 'Some Other Name', result.value.name
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.update(id: species.id, name: 'a' * (max + 1))

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::TOO_LONG, result.error[:name]
      end

      it 'does not complain when name is max length' do
        max = 255
        result = operation.create(id: species.id, group_id: group.id, name: 'a' * max)

        assert_predicate result, :success?
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create(name: 'Some Other Name', group_id: group.id)

        assert_predicate result, :success?

        result = operation.update(id: species.id, name: ' some OTHER name ')

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'requires description length to be less than 4096 characters' do
        description = 'a' * (4096 + 1)
        result = operation.update(id: species.id, description: description)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::TOO_LONG, result.error[:description]
      end

      it 'allows description length to be equal to 4096 characters' do
        description = 'a' * 4096
        result = operation.update(id: species.id, group_id: group.id, description: description)

        assert_predicate result, :success?
      end

      it 'requires environmental preferences length to be less than 4096 characters' do
        environmental_preferences = 'a' * (4096 + 1)
        result = operation.update(id: species.id, environmental_preferences: environmental_preferences)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::TOO_LONG, result.error[:environmental_preferences]
      end

      it 'allows environmental preferences length to be equal to 4096 characters' do
        environmental_preferences = 'a' * 4096
        result = operation.update(id: species.id, environmental_preferences: environmental_preferences)

        assert_predicate result, :success?
      end
    end
  end

  describe '#add_feature' do
    let(:species) do
      happy_operation.create(name: 'Some Name', group_id: group.id).value
    end
    let(:field) do
      happy_operation_for(Paleolog::Repository::Field, user).create(
        name: 'Some Field', group_id: group.id,
      ).value
    end
    let(:choice) do
      happy_operation_for(Paleolog::Repository::Field, user).add_choice(
        name: 'Some Choice', field_id: field.id,
      ).value
    end

    it 'requires authenticated user' do
      authorizer.expect :authenticated?, false

      operation.add_feature(species_id: species.id, choice_id: choice.id)
               .on_success { flunk "Expected error, got #{_1}" }
               .on_failure do |error|
        assert Paleolog::Operation.unauthenticated?(error)
      end

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
      end

      it 'adds new feature' do
        result = operation.add_feature(species_id: species.id, choice_id: choice.id)

        assert_predicate result, :success?
        new_feature = result.value

        assert_equal choice.id, new_feature.choice_id
        assert_equal species.id, new_feature.species_id
      end

      it 'complains when choice_id blank' do
        result = operation.add_feature(species_id: species.id, choice_id: nil)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::NON_INTEGER, result.error[:choice_id]
      end

      it 'complains when species_id blank' do
        result = operation.add_feature(species_id: nil, choice_id: choice.id)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::NON_INTEGER, result.error[:species_id]
      end

      it 'complains when choice_id missing' do
        result = operation.add_feature(species_id: species.id)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING, result.error[:choice_id]
      end

      it 'complains when species_id missing' do
        result = operation.add_feature(choice_id: choice.id)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING, result.error[:species_id]
      end
    end
  end

  describe '#create' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.create(name: 'Just a Name')

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthenticated?(result.error)

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
      end

      it 'does not complain when name not taken yet' do
        result = operation.create(name: 'Some Name', group_id: group.id)

        assert_predicate result, :success?
      end

      it 'complains when group_id blank' do
        result = operation.create(name: 'Name', group_id: nil)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::NON_INTEGER, result.error[:group_id]
      end

      it 'complains when group_id missing' do
        result = operation.create(name: 'Name')

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING, result.error[:group_id]
      end

      it 'complains when name is nil' do
        result = operation.create(name: nil, group_id: group.id)

        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.create(name: '  ', group_id: group.id)

        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(name: 'Some Name', group_id: group.id)

        assert_predicate result, :success?

        result = operation.create(name: 'Some Name', group_id: group.id)

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'allows same name for different group' do
        other_group = happy_operation_for(Paleolog::Repository::Group, user).create(name: 'Other Group').value
        result = happy_operation.create(name: 'Some Name', group_id: other_group.id)

        assert_predicate result, :success?

        result = operation.create(name: 'Some Name', group_id: group.id)

        assert_predicate result, :success?
        assert_equal 'Some Name', result.value.name
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.create(name: 'a' * (max + 1), group_id: group.id)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::TOO_LONG, result.error[:name]
      end

      it 'does not complain when name is max length' do
        max = 255
        result = operation.create(name: 'a' * max, group_id: group.id)

        assert_predicate result, :success?
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create(name: 'Some Name', group_id: group.id)

        assert_predicate result, :success?

        result = operation.create(name: ' some name ', group_id: group.id)

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'requires description length to be less than 4096 characters' do
        description = 'a' * (4096 + 1)
        result = operation.create(
          { group_id: group.id, name: 'Name', description: description },
        )

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::TOO_LONG, result.error[:description]
      end

      it 'allows description length to be equal to 4096 characters' do
        description = 'a' * 4096
        result = operation.create(
          { group_id: group.id, name: 'Name', description: description },
        )

        assert_predicate result, :success?
      end

      it 'requires environmental preferences length to be less than 4096 characters' do
        environmental_preferences = 'a' * (4096 + 1)
        result = operation.create(
          { group_id: group.id, name: 'Name', environmental_preferences: environmental_preferences },
        )

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::TOO_LONG, result.error[:environmental_preferences]
      end

      it 'allows environmental preferences length to be equal to 4096 characters' do
        environmental_preferences = 'a' * 4096
        result = operation.create(
          { group_id: group.id, name: 'Name', environmental_preferences: environmental_preferences },
        )

        assert_predicate result, :success?
      end
    end
  end
end
