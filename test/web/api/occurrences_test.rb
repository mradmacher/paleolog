# frozen_string_literal: true

require 'web_helper'

describe 'Occurrences' do
  include Rack::Test::Methods

  let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'some project')) }
  let(:counting) { Paleolog::Repo.save(Paleolog::Counting.new(name: 'some counting', project: project)) }
  let(:section) { Paleolog::Repo.save(Paleolog::Section.new(name: 'some section', project: project)) }
  let(:sample) { Paleolog::Repo.save(Paleolog::Sample.new(name: 'some sample', section: section)) }

  let(:group1) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate')) }
  let(:group2) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Other')) }
  let(:species11) { Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Odontochitina costata')) }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:session) { {} }

  # rubocop:disable Metrics/AbcSize
  def assert_requires_manager(action, project)
    user = Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123'))

    action.call
    assert_equal 401, last_response.status

    session = {}
    Paleolog::Authorizer.new(session).login('test', 'test123')
    env 'rack.session', session
    action.call
    assert_equal 403, last_response.status

    participation = Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project))
    action.call
    assert_equal 403, last_response.status

    Paleolog::Repo::ResearchParticipation.update(participation.id, manager: true)
    action.call
    assert last_response.ok?
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def assert_requires_observer(action, project)
    user = Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123'))

    action.call
    assert_equal 401, last_response.status

    session = {}
    Paleolog::Authorizer.new(session).login('test', 'test123')
    env 'rack.session', session
    action.call
    assert_equal 403, last_response.status

    participation = Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project))
    action.call
    assert last_response.ok?

    Paleolog::Repo::ResearchParticipation.update(participation.id, manager: true)
    action.call
    assert last_response.ok?
  end
  # rubocop:enable Metrics/AbcSize

  after do
    Paleolog::Repo::User.delete_all
    Paleolog::Repo::Occurrence.delete_all
  end

  describe 'GET /api/projects/:project_id/occurrences' do
    it 'requires user participating in the project' do
      params = { sample_id: sample.id, counting_id: counting.id }
      assert_requires_observer(-> { get "/api/projects/#{project.id}/occurrences", params }, project)
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project))
        Paleolog::Authorizer.new(session).login('test', 'test123')
        env 'rack.session', session
      end

      it 'returns empty collection when there are no occurrences' do
        params = { sample_id: sample.id, counting_id: counting.id }
        get "/api/projects/#{project.id}/occurrences", params
        assert last_response.ok?, "Expected 200, but got #{last_response.status}"
        response_body = JSON.parse(last_response.body)
        assert response_body['occurrences'].empty?

        assert_equal 0, response_body['summary']['countable']
        assert_equal 0, response_body['summary']['uncountable']
        assert_equal 0, response_body['summary']['total']
      end

      it 'returns all necessary attributes' do
        occurrence = Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species11, quantity: 1))
        params = { sample_id: sample.id, counting_id: counting.id }
        get "/api/projects/#{project.id}/occurrences", params
        result = JSON.parse(last_response.body)['occurrences']
        assert 1, result.size
        result = result.first
        assert_equal occurrence.id, result['id']
        assert_equal species11.name, result['species_name']
        assert_equal species11.group.name, result['group_name']
        assert_equal occurrence.quantity, result['quantity']
        assert_equal occurrence.status, result['status']
        assert_equal occurrence.uncertain, result['uncertain']
      end

      it 'does not return occurrences for other sample' do
        other_sample = Paleolog::Repo.save(Paleolog::Sample.new(name: 'other sample', section: section))
        Paleolog::Repo.save(Paleolog::Occurrence.new(sample: other_sample, counting: counting, species: species11))
        params = { sample_id: sample.id, counting_id: counting.id }
        get "/api/projects/#{project.id}/occurrences", params
        result = JSON.parse(last_response.body)['occurrences']
        assert 0, result.size
      end

      it 'does not return occurrences for other counting' do
        other_counting = Paleolog::Repo.save(Paleolog::Counting.new(name: 'other counting', project: project))
        Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: other_counting, species: species11))
        params = { sample_id: sample.id, counting_id: counting.id }
        get "/api/projects/#{project.id}/occurrences", params
        result = JSON.parse(last_response.body)['occurrences']
        assert 0, result.size
      end

      it 'returns all occurrences for given sample and counting in right order' do
        species1 = Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Species 1'))
        species2 = Paleolog::Repo.save(Paleolog::Species.new(group: group2, name: 'Species 2'))
        species3 = Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Species 3'))
        Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species1, rank: 3))
        Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species2, rank: 1))
        Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species3, rank: 2))


        params = { sample_id: sample.id, counting_id: counting.id }
        get "/api/projects/#{project.id}/occurrences", params
        result = JSON.parse(last_response.body)['occurrences']
        assert 3, result.size
        assert_equal 'Species 2', result[0]['species_name']
        assert_equal 'Species 3', result[1]['species_name']
        assert_equal 'Species 1', result[2]['species_name']
      end
    end
  end

  describe 'POST /api/projects/:project_id/occurrences' do
    it 'requires user participating in the project as manager' do
      params = { sample_id: sample.id, species_id: species11.id, counting_id: counting.id }
      assert_requires_manager(-> { post "/api/projects/#{project.id}/occurrences", params }, project)
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: true))
        Paleolog::Authorizer.new(session).login('test', 'test123')
        env 'rack.session', session
      end

      it 'creates new occurrence' do
        params = { sample_id: sample.id, species_id: species11.id, counting_id: counting.id }
        post "/api/projects/#{project.id}/occurrences", params
        assert last_response.ok?, "Expected 200, but got #{last_response.status}"
        response_body = JSON.parse(last_response.body)
        refute_nil Paleolog::Repo::Occurrence.find(response_body['occurrence']['id'])
      end

      it 'ensures sample is from project' do
        other_project = Paleolog::Repo.save(Paleolog::Project.new(name: 'some other project'))
        other_section = Paleolog::Repo.save(Paleolog::Section.new(name: 'some other section', project: other_project))
        other_sample = Paleolog::Repo.save(Paleolog::Sample.new(name: 'some other sample', section: other_section))
        params = { sample_id: other_sample.id, species_id: species11.id, counting_id: counting.id }
        post "/api/projects/#{project.id}/occurrences", params
        assert_equal 400, last_response.status
        response_body = JSON.parse(last_response.body)
        assert_equal 'non_integer', response_body['sample_id']
      end

      it 'ensures counting is from project' do
        other_project = Paleolog::Repo.save(Paleolog::Project.new(name: 'some other project'))
        other_counting = Paleolog::Repo.save(Paleolog::Counting.new(name: 'some other counting',
                                                                    project: other_project,))
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
        assert_equal ['non_integer', 'non_integer', 'non_integer'], response_body.values
      end
    end
  end

  describe 'DELETE /api/projects/:project_id/occurrences/:id' do
    let(:occurrence) do
      Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species11))
    end

    it 'requires user participating in the project as manager' do
      assert_requires_manager(-> { delete "/api/projects/#{project.id}/occurrences/#{occurrence.id}" }, project)
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: true))
        Paleolog::Authorizer.new(session).login('test', 'test123')
        env 'rack.session', session
      end

      it 'removes occurrence' do
        refute_nil Paleolog::Repo::Occurrence.find(occurrence.id)
        delete "/api/projects/#{project.id}/occurrences/#{occurrence.id}"
        assert last_response.ok?, "Expected 200 but got #{last_response.status}"
        assert_nil Paleolog::Repo::Occurrence.find(occurrence.id)
      end

      it 'is 404 when occurrence does not exist' do
        delete "/api/projects/#{project.id}/occurrences/0"
        assert_equal 404, last_response.status
      end
    end
  end

  describe 'PATCH /api/projects/:project_id/occurrences/:id' do
    it 'requires user participating in the project as manager' do
      occurrence = Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species11))
      assert_requires_manager(-> { patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}" }, project)
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: true))
        post '/login', { login: 'test', password: 'test123' }
      end

      it 'works' do
        occurrence = Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting,
                                                                  species: species11,))
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}"
        assert last_response.ok?
      end

      it 'does not allow changing sample, species nor counting' do
        occurrence = Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting,
                                                                  species: species11,))
        other_counting = Paleolog::Repo.save(Paleolog::Counting.new(name: 'some other counting', project: project))
        other_sample = Paleolog::Repo.save(Paleolog::Sample.new(name: 'some other sample', section: section))
        other_species = Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Other costata'))
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", {
          counting_id: other_counting.id,
          sample_id: other_sample.id,
          species_id: other_species.id,
          shift: '1',
        }
        assert last_response.ok?
        updated_occurrence = Paleolog::Repo.find(Paleolog::Occurrence, occurrence.id)
        assert occurrence.sample_id == updated_occurrence.sample_id
        assert occurrence.counting_id == updated_occurrence.counting_id
        assert occurrence.species_id == updated_occurrence.species_id
      end

      it 'is 404 when occurrence does not exist' do
        patch "/api/projects/#{project.id}/occurrences/0"
        assert_equal 404, last_response.status
      end

      it 'shifts quantity up' do
        occurrence = Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting,
                                                                  species: species11,))
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { shift: '1' }
        assert last_response.ok?
        result = JSON.parse(last_response.body)
        assert_equal 1, result['summary']['countable']
        assert_equal 0, result['summary']['uncountable']
        assert_equal 1, result['summary']['total']
        assert_equal occurrence.id, result['occurrence']['id']
        assert_equal 1, result['occurrence']['quantity']
      end

      it 'shifts quantity down' do
        occurrence = Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting,
                                                                  species: species11, quantity: 2,))
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { shift: '-1' }
        assert last_response.ok?
        result = JSON.parse(last_response.body)
        assert_equal 1, result['summary']['countable']
        assert_equal 0, result['summary']['uncountable']
        assert_equal 1, result['summary']['total']
        assert_equal occurrence.id, result['occurrence']['id']
        assert_equal 1, result['occurrence']['quantity']
      end

      it 'does not shift quantity lower than 0' do
        occurrence = Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting,
                                                                  species: species11, quantity: 1,))
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { shift: '-1' }
        assert last_response.ok?
        result = JSON.parse(last_response.body)
        assert_equal 0, result['occurrence']['quantity']

        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { shift: '-1' }
        assert last_response.ok?, "Expected 200, but got #{last_response.status}"
        result = JSON.parse(last_response.body)
        assert_nil result['occurrence']['quantity']
      end

      it 'sets status' do
        occurrence = Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting,
                                                                  species: species11, quantity: 1,))
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { status: Paleolog::Occurrence::CARVING }
        assert last_response.ok?
        result = JSON.parse(last_response.body)
        assert_equal 0, result['summary']['countable']
        assert_equal 1, result['summary']['uncountable']
        assert_equal 1, result['summary']['total']
        assert_equal occurrence.id, result['occurrence']['id']
        assert_equal 1, result['occurrence']['quantity']
        assert_equal Paleolog::Occurrence::CARVING, result['occurrence']['status']
        assert_equal 'c', result['occurrence']['status_symbol']

        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { status: Paleolog::Occurrence::NORMAL }
        assert last_response.ok?
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
        occurrence = Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting,
                                                                  species: species11, quantity: 1,))
        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { uncertain: 'true' }
        assert last_response.ok?
        result = JSON.parse(last_response.body)
        assert_equal 1, result['summary']['countable']
        assert_equal 0, result['summary']['uncountable']
        assert_equal 1, result['summary']['total']
        assert_equal occurrence.id, result['occurrence']['id']
        assert_equal 1, result['occurrence']['quantity']
        assert result['occurrence']['uncertain']

        patch "/api/projects/#{project.id}/occurrences/#{occurrence.id}", { uncertain: 'false' }
        assert last_response.ok?
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
