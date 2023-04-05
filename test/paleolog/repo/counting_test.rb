# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Counting do
  let(:repo) { Paleolog::Repo::Counting }

  after do
    repo.delete_all
    Paleolog::Repo::Project.delete_all
  end

  describe '#find_for_project' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Some Project')) }
    let(:other_project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Other Project')) }

    it 'returns counting by id for given project id' do
      c1 = Paleolog::Repo.save(Paleolog::Counting.new(name: 'C1', project: project))
      Paleolog::Repo.save(Paleolog::Counting.new(name: 'C2', project: project))
      Paleolog::Repo.save(Paleolog::Counting.new(name: 'C3', project: other_project))
      Paleolog::Repo.save(Paleolog::Counting.new(name: 'C4', project: other_project))

      result = repo.find_for_project(c1.id, project.id)
      assert_equal(c1, result)

      result = repo.find_for_project(c1.id, other_project.id)
      assert_nil(result)
    end

    it 'loads counted group and marker' do
      group = Paleolog::Repo.save(Paleolog::Group.new(name: 'Counted Group'))
      marker = Paleolog::Repo.save(Paleolog::Species.new(name: 'Marker', group: group))
      counting = Paleolog::Repo.save(Paleolog::Counting.new(name: 'C1', project: project, group: group, marker: marker))

      result = repo.find_for_project(counting.id, project.id)
      assert_equal(group, result.group)
      assert_equal(marker, result.marker)
    end
  end

  describe '#similar_name_exists?' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Some project')) }

    after do
      Paleolog::Repo::Project.delete_all
    end

    it 'checks name uniqueness within project scope' do
      common_name = 'Some name'
      Paleolog::Repo.save(Paleolog::Counting.new(name: common_name, project: project))

      assert(repo.similar_name_exists?(common_name, project_id: project.id))
      refute(repo.similar_name_exists?("#{common_name}123", project_id: project.id))
    end

    it 'does not check name uniqueness accross different projects' do
      common_name = 'Some name'
      other_project = Paleolog::Repo.save(Paleolog::Project.new(name: 'Other project'))
      Paleolog::Repo.save(Paleolog::Counting.new(name: common_name, project: project))

      refute(repo.similar_name_exists?(common_name, project_id: other_project.id))
    end

    it 'is case insensitive' do
      Paleolog::Repo.save(Paleolog::Counting.new(name: 'Some name', project: project))

      assert(repo.similar_name_exists?('soMe nAmE', project_id: project.id))
    end
  end
end
