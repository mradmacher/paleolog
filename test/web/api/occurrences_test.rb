# frozen_string_literal: true

require 'web_helper'

describe 'Occurrences' do
  include Rack::Test::Methods

  let(:user) do
    Paleolog::Repo.find(
      Paleolog::User,
      Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')),
    )
  end
  let(:project) do
    happy_operation_for(Paleolog::Operation::Project, user)
      .create(name: 'Some Project')
      .value
  end
  let(:researcher) do
    Paleolog::Repo::Researcher.find_for_project_and_user(project.id, user.id)
  end
  let(:counting) do
    happy_operation_for(Paleolog::Operation::Counting, user)
      .create(name: 'some counting', project_id: project.id)
      .value
  end
  let(:section) do
    happy_operation_for(Paleolog::Operation::Section, user)
      .create(name: 'some section', project_id: project.id)
      .value
  end
  let(:sample) do
    happy_operation_for(Paleolog::Operation::Sample, user)
      .create(name: 'some sample', section_id: section.id)
      .value
  end
  let(:group1) do
    happy_operation_for(Paleolog::Operation::Group, user)
      .create(name: 'Dinoflagellate')
      .value
  end
  let(:group2) do
    happy_operation_for(Paleolog::Operation::Group, user)
      .create(name: 'Other')
      .value
  end
  let(:species11) do
    happy_operation_for(Paleolog::Operation::Species, user)
      .create(group_id: group1.id, name: 'Odontochitina costata')
      .value
  end
  let(:session) { {} }

  after do
    Paleolog::Repo.delete_all(Paleolog::Occurrence)
    Paleolog::Repo.delete_all(Paleolog::Species)
    Paleolog::Repo.delete_all(Paleolog::Group)
    Paleolog::Repo.delete_all(Paleolog::Sample)
    Paleolog::Repo.delete_all(Paleolog::Section)
    Paleolog::Repo.delete_all(Paleolog::Counting)
    Paleolog::Repo.delete_all(Paleolog::User)
    Paleolog::Repo.delete_all(Paleolog::Researcher)
    Paleolog::Repo.delete_all(Paleolog::Project)
  end

  describe 'GET /api/projects/:project_id/occurrences' do
    it 'rejects guest access' do
      params = { sample_id: sample.id, counting_id: counting.id }

      assert_unauthorized(-> { get "/api/projects/#{project.id}/occurrences", params })
    end

    it 'accepts user participating in the project' do
      params = { sample_id: sample.id, counting_id: counting.id }
      login(user)

      assert_permitted(-> { get "/api/projects/#{project.id}/occurrences", params })
    end

    describe 'with user' do
      before do
        login(user)
      end

      it 'returns empty collection when there are no occurrences' do
        params = { sample_id: sample.id, counting_id: counting.id }
        get "/api/projects/#{project.id}/occurrences", params

        assert_predicate last_response, :ok?, "Expected 200, but got #{last_response.status}"
        response_body = JSON.parse(last_response.body)

        assert_empty response_body['occurrences']

        assert_equal 0, response_body['summary']['countable']
        assert_equal 0, response_body['summary']['uncountable']
        assert_equal 0, response_body['summary']['total']
      end

      it 'returns all necessary attributes' do
        occurrence = happy_operation_for(Paleolog::Operation::Occurrence, user).create(
          sample_id: sample.id,
          counting_id: counting.id,
          species_id: species11.id,
        ).value
        occurrence = happy_operation_for(Paleolog::Operation::Occurrence, user).update(
          id: occurrence.id,
          quantity: 1,
        ).value

        params = { sample_id: sample.id, counting_id: counting.id }
        get "/api/projects/#{project.id}/occurrences", params
        result = JSON.parse(last_response.body)['occurrences']

        assert_equal 1, result.size
        result = result.first

        assert_equal occurrence.id, result['id']
        assert_equal species11.name, result['species_name']
        assert_equal species11.group.name, result['group_name']
        assert_equal occurrence.quantity, result['quantity']
        assert_equal occurrence.status, result['status']
        assert_equal occurrence.uncertain, result['uncertain']
      end

      it 'does not return occurrences for other sample' do
        other_sample = happy_operation_for(Paleolog::Operation::Sample, user)
                       .create(name: 'other sample', section_id: section.id)
                       .value
        happy_operation_for(Paleolog::Operation::Occurrence, user).create(
          sample_id: other_sample.id,
          counting_id: counting.id,
          species_id: species11.id,
        ).value
        params = { sample_id: sample.id, counting_id: counting.id }
        get "/api/projects/#{project.id}/occurrences", params
        result = JSON.parse(last_response.body)['occurrences']

        assert_equal 0, result.size
      end

      it 'does not return occurrences for other counting' do
        other_counting = happy_operation_for(Paleolog::Operation::Counting, user)
                         .create(name: 'other counting', project_id: project.id)
                         .value
        happy_operation_for(Paleolog::Operation::Occurrence, user).create(
          sample_id: sample.id,
          counting_id: other_counting.id,
          species_id: species11.id,
        ).value
        params = { sample_id: sample.id, counting_id: counting.id }
        get "/api/projects/#{project.id}/occurrences", params
        result = JSON.parse(last_response.body)['occurrences']

        assert_equal 0, result.size
      end

      it 'returns all occurrences for given sample and counting in right order' do
        species1 = happy_operation_for(Paleolog::Operation::Species, user)
                   .create(group_id: group1.id, name: 'Species 1')
                   .value
        species2 = happy_operation_for(Paleolog::Operation::Species, user)
                   .create(group_id: group2.id, name: 'Species 2')
                   .value
        species3 = happy_operation_for(Paleolog::Operation::Species, user)
                   .create(group_id: group1.id, name: 'Species 3')
                   .value

        Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species1, rank: 3))
        Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species2, rank: 1))
        Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species3, rank: 2))

        params = { sample_id: sample.id, counting_id: counting.id }
        get "/api/projects/#{project.id}/occurrences", params
        result = JSON.parse(last_response.body)['occurrences']

        assert_equal 3, result.size
        assert_equal 'Species 2', result[0]['species_name']
        assert_equal 'Species 3', result[1]['species_name']
        assert_equal 'Species 1', result[2]['species_name']
      end
    end
  end

  describe 'POST /api/projects/:project_id/occurrences' do
    it 'rejects guest access' do
      params = { sample_id: sample.id, species_id: species11.id, counting_id: counting.id }

      assert_unauthorized(-> { post "/api/projects/#{project.id}/occurrences", params })
    end

    it 'rejects user observing the project' do
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: false))
      params = { sample_id: sample.id, species_id: species11.id, counting_id: counting.id }
      login(user)

      assert_forbidden(-> { post "/api/projects/#{project.id}/occurrences", params })
    end

    it 'accepts user managing the project' do
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: true))
      params = { sample_id: sample.id, species_id: species11.id, counting_id: counting.id }
      login(user)

      assert_permitted(-> { post "/api/projects/#{project.id}/occurrences", params })
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: true))
        login(user)
      end

      it 'creates new occurrence' do
        params = { sample_id: sample.id, species_id: species11.id, counting_id: counting.id }
        post "/api/projects/#{project.id}/occurrences", params

        assert_predicate last_response, :ok?, "Expected 200, but got #{last_response.status}"
        response_body = JSON.parse(last_response.body)

        refute_nil Paleolog::Repo.find(Paleolog::Occurrence, response_body['occurrence']['id'])
      end

      it 'ensures sample is from project' do
        other_project = happy_operation_for(Paleolog::Operation::Project, user)
                        .create(name: 'some other project')
                        .value
        other_section = happy_operation_for(Paleolog::Operation::Section, user)
                        .create(name: 'some other section', project_id: other_project.id)
                        .value
        other_sample = happy_operation_for(Paleolog::Operation::Sample, user)
                       .create(name: 'some other sample', section_id: other_section.id)
                       .value
        params = { sample_id: other_sample.id, species_id: species11.id, counting_id: counting.id }
        post "/api/projects/#{project.id}/occurrences", params

        assert_equal 400, last_response.status
        response_body = JSON.parse(last_response.body)

        assert_equal 'non_integer', response_body['sample_id']
      end

      it 'ensures counting is from project' do
        other_project = happy_operation_for(Paleolog::Operation::Project, user)
                        .create(name: 'some other project')
                        .value
        other_counting = happy_operation_for(Paleolog::Operation::Counting, user)
                         .create(name: 'some other counting', project_id: other_project.id)
                         .value
        params = { sample_id: sample.id, species_id: species11.id, counting_id: other_counting.id }
        post "/api/projects/#{project.id}/occurrences", params

        assert_equal 400, last_response.status
        response_body = JSON.parse(last_response.body)

        assert_equal 'non_integer', response_body['counting_id']
      end

      it 'validates created occurrence' do
        params = {}
        post "/api/projects/#{project.id}/occurrences", params

        assert_equal 400, last_response.status
        response_body = JSON.parse(last_response.body)

        assert_equal %w[counting_id sample_id species_id], response_body.keys
        assert_equal %w[non_integer non_integer non_integer], response_body.values
      end
    end
  end

  describe 'DELETE /api/projects/:project_id/occurrences/:id' do
    let(:occurrence) do
      happy_operation_for(Paleolog::Operation::Occurrence, user).create(
        sample_id: sample.id,
        counting_id: counting.id,
        species_id: species11.id,
      ).value
    end

    it 'rejects guest access' do
      assert_unauthorized(-> { delete "/api/projects/#{project.id}/occurrences/#{occurrence.id}", {} })
    end

    it 'rejects user observing the project' do
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: false))
      login(user)

      assert_forbidden(-> { delete "/api/projects/#{project.id}/occurrences/#{occurrence.id}", {} })
    end

    it 'accepts user managing the project' do
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: true))
      login(user)

      assert_permitted(-> { delete "/api/projects/#{project.id}/occurrences/#{occurrence.id}", {} })
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: true))
        login(user)
      end

      it 'removes occurrence' do
        refute_nil Paleolog::Repo.find(Paleolog::Occurrence, occurrence.id)
        delete "/api/projects/#{project.id}/occurrences/#{occurrence.id}"

        assert_predicate last_response, :ok?, "Expected 200 but got #{last_response.status}"
        assert_nil Paleolog::Repo.find(Paleolog::Occurrence, occurrence.id)
      end

      it 'is 404 when occurrence does not exist' do
        delete "/api/projects/#{project.id}/occurrences/0"

        assert_equal 404, last_response.status
      end
    end
  end

  describe 'PATCH /api/projects/:project_id/occurrences/:id' do
    let(:occurrence) do
      happy_operation_for(Paleolog::Operation::Occurrence, user).create(
        sample_id: sample.id,
        counting_id: counting.id,
        species_id: species11.id,
      ).value
    end

    it 'rejects guest access' do
      params = { shift: '1' }

      assert_unauthorized(-> { patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", params })
    end

    it 'rejects user observing the project' do
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: false))
      params = { shift: '1' }
      login(user)

      assert_forbidden(-> { patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", params })
    end

    it 'accepts user managing the project' do
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: true))
      params = { shift: '1' }
      login(user)

      assert_permitted(-> { patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", params })
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: true))
        login(user)
      end

      it 'works' do
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}"

        assert_predicate last_response, :ok?
      end

      it 'does not allow changing sample, species nor counting' do
        other_counting = happy_operation_for(Paleolog::Operation::Counting, user)
                         .create(name: 'some other counting', project_id: project.id)
                         .value
        other_sample = happy_operation_for(Paleolog::Operation::Sample, user)
                       .create(name: 'some other sample', section_id: section.id)
                       .value
        other_species = happy_operation_for(Paleolog::Operation::Species, user)
                        .create(group_id: group1.id, name: 'Other costata')
                        .value

        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", {
          counting_id: other_counting.id,
          sample_id: other_sample.id,
          species_id: other_species.id,
          shift: '1',
        }

        assert_predicate last_response, :ok?
        updated_occurrence = Paleolog::Repo.find(Paleolog::Occurrence, occurrence.id)

        assert_equal occurrence.sample_id, updated_occurrence.sample_id
        assert_equal occurrence.counting_id, updated_occurrence.counting_id
        assert_equal occurrence.species_id, updated_occurrence.species_id
      end

      it 'is 404 when occurrence does not exist' do
        patch "/api/projects/#{project.id}/occurrences/0"

        assert_equal 404, last_response.status
      end

      it 'shifts quantity up' do
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { shift: '1' }

        assert_predicate last_response, :ok?
        result = JSON.parse(last_response.body)

        assert_equal 1, result['summary']['countable']
        assert_equal 0, result['summary']['uncountable']
        assert_equal 1, result['summary']['total']
        assert_equal occurrence.id, result['occurrence']['id']
        assert_equal 1, result['occurrence']['quantity']
      end

      it 'shifts quantity down' do
        happy_operation_for(Paleolog::Operation::Occurrence, user)
          .update(id: occurrence.id, quantity: 5).value
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { shift: '-1' }

        assert_predicate last_response, :ok?
        result = JSON.parse(last_response.body)

        assert_equal 4, result['summary']['countable']
        assert_equal 0, result['summary']['uncountable']
        assert_equal 4, result['summary']['total']
        assert_equal occurrence.id, result['occurrence']['id']
        assert_equal 4, result['occurrence']['quantity']
      end

      it 'does not shift quantity lower than 0' do
        happy_operation_for(Paleolog::Operation::Occurrence, user)
          .update(id: occurrence.id, quantity: 1).value
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { shift: '-1' }

        assert_predicate last_response, :ok?
        result = JSON.parse(last_response.body)

        assert_equal 0, result['occurrence']['quantity']

        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { shift: '-1' }

        assert_predicate last_response, :ok?, "Expected 200, but got #{last_response.status}"
        result = JSON.parse(last_response.body)

        assert_nil result['occurrence']['quantity']
      end

      it 'sets status' do
        happy_operation_for(Paleolog::Operation::Occurrence, user)
          .update(id: occurrence.id, quantity: 1).value
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { status: Paleolog::Occurrence::CARVING }

        assert_predicate last_response, :ok?
        result = JSON.parse(last_response.body)

        assert_equal 0, result['summary']['countable']
        assert_equal 1, result['summary']['uncountable']
        assert_equal 1, result['summary']['total']
        assert_equal occurrence.id, result['occurrence']['id']
        assert_equal 1, result['occurrence']['quantity']
        assert_equal Paleolog::Occurrence::CARVING, result['occurrence']['status']
        assert_equal 'c', result['occurrence']['status_symbol']

        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { status: Paleolog::Occurrence::NORMAL }

        assert_predicate last_response, :ok?
        result = JSON.parse(last_response.body)

        assert_equal 1, result['summary']['countable']
        assert_equal 0, result['summary']['uncountable']
        assert_equal 1, result['summary']['total']
        assert_equal occurrence.id, result['occurrence']['id']
        assert_equal 1, result['occurrence']['quantity']
        assert_equal Paleolog::Occurrence::NORMAL, result['occurrence']['status']
        assert_equal '', result['occurrence']['status_symbol']
      end

      it 'sets uncertain' do
        happy_operation_for(Paleolog::Operation::Occurrence, user)
          .update(id: occurrence.id, quantity: 1).value
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { uncertain: 'true' }

        assert_predicate last_response, :ok?
        result = JSON.parse(last_response.body)

        assert_equal 1, result['summary']['countable']
        assert_equal 0, result['summary']['uncountable']
        assert_equal 1, result['summary']['total']
        assert_equal occurrence.id, result['occurrence']['id']
        assert_equal 1, result['occurrence']['quantity']
        assert result['occurrence']['uncertain']

        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { uncertain: 'false' }

        assert_predicate last_response, :ok?
        result = JSON.parse(last_response.body)

        assert_equal 1, result['summary']['countable']
        assert_equal 0, result['summary']['uncountable']
        assert_equal 1, result['summary']['total']
        assert_equal occurrence.id, result['occurrence']['id']
        assert_equal 1, result['occurrence']['quantity']
        refute result['occurrence']['uncertain']
      end
    end
  end
end
