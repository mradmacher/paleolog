# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Counting do
  let(:repo) { Paleolog::Repo::Counting }
  let(:project_id) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Some Project')) }

  after do
    repo.delete_all
    Paleolog::Repo.delete_all(Paleolog::Project)
  end

  describe '#find_for_project' do
    let(:other_project_id) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Other Project')) }

    it 'returns counting by id for given project id' do
      c1_id = Paleolog::Repo.save(Paleolog::Counting.new(name: 'C1', project_id: project_id))
      Paleolog::Repo.save(Paleolog::Counting.new(name: 'C2', project_id: project_id))
      Paleolog::Repo.save(Paleolog::Counting.new(name: 'C3', project_id: other_project_id))
      Paleolog::Repo.save(Paleolog::Counting.new(name: 'C4', project_id: other_project_id))

      result = repo.find_for_project(c1_id, project_id)
      assert_equal(c1_id, result.id)

      result = repo.find_for_project(c1_id, other_project_id)
      assert_nil(result)
    end

    it 'loads counted group and marker' do
      group_id = Paleolog::Repo.save(
        Paleolog::Group.new(name: 'Counted Group'),
      )
      marker_id = Paleolog::Repo.save(
        Paleolog::Species.new(name: 'Marker', group_id: group_id),
      )
      counting_id = Paleolog::Repo.save(
        Paleolog::Counting.new(name: 'C1', project_id: project_id, group_id: group_id, marker_id: marker_id),
      )

      result = repo.find_for_project(counting_id, project_id)
      assert_equal(group_id, result.group.id)
      assert_equal(marker_id, result.marker.id)
    end
  end

  describe '#similar_name_exists?' do
    it 'checks name uniqueness within project scope' do
      common_name = 'Some name'
      Paleolog::Repo.save(Paleolog::Counting.new(name: common_name, project_id: project_id))

      assert(repo.similar_name_exists?(common_name, project_id: project_id))
      refute(repo.similar_name_exists?("#{common_name}123", project_id: project_id))
    end

    it 'does not check name uniqueness accross different projects' do
      common_name = 'Some name'
      other_project_id = Paleolog::Repo.save(Paleolog::Project.new(name: 'Other project'))
      Paleolog::Repo.save(Paleolog::Counting.new(name: common_name, project_id: project_id))

      refute(repo.similar_name_exists?(common_name, project_id: other_project_id))
    end

    it 'is case insensitive' do
      Paleolog::Repo.save(Paleolog::Counting.new(name: 'Some name', project_id: project_id))

      assert(repo.similar_name_exists?('soMe nAmE', project_id: project_id))
    end
  end
end
