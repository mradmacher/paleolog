# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Section do
  let(:repo) { Paleolog::Repo::Section }
  let(:project_id) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Some Project')) }

  after do
    repo.delete_all
    Paleolog::Repo::Project.delete_all
  end

  describe '#find_for_project' do
    it 'returns section by id for given project' do
      other_project_id = Paleolog::Repo.save(Paleolog::Project.new(name: 'Other Project'))
      section = repo.find(Paleolog::Repo.save(Paleolog::Section.new(name: 'S1', project_id: project_id)))
      Paleolog::Repo.save(Paleolog::Section.new(name: 'S2', project_id: other_project_id))

      result = repo.find_for_project(section.id, project_id)

      assert_equal(section, result)

      result = repo.find_for_project(section.id, other_project_id)

      assert_nil(result)
    end

    it 'loads samples' do
      section_id = Paleolog::Repo.save(Paleolog::Section.new(name: 'Section', project_id: project_id))
      sample1_id = Paleolog::Repo.save(Paleolog::Sample.new(name: 'S1', section_id: section_id))
      sample2_id = Paleolog::Repo.save(Paleolog::Sample.new(name: 'S2', section_id: section_id))

      result = repo.find_for_project(section_id, project_id)

      assert_equal([sample1_id, sample2_id].sort, result.samples.map(&:id).sort)
    end
  end

  describe '#all_for_project' do
    let(:other_project_id) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Other Project')) }

    it 'returns sections for given project' do
      section1_id = Paleolog::Repo.save(Paleolog::Section.new(name: 'S1', project_id: project_id))
      section2_id = Paleolog::Repo.save(Paleolog::Section.new(name: 'S2', project_id: project_id))
      Paleolog::Repo.save(Paleolog::Section.new(name: 'S3', section_id: other_project_id))

      result = repo.all_for_project(project_id)

      assert_equal([section1_id, section2_id].sort, result.map(&:id).sort)
    end
  end

  describe '#find' do
    let(:section) do
      repo.find(Paleolog::Repo.save(Paleolog::Section.new(name: 'Some section', project_id: project_id)))
    end

    it 'returns section with given id' do
      result = repo.find(section.id)

      assert_equal(section, result)
    end

    it 'returns nil when section with given id does not exist' do
      result = repo.find(section.id + 1)

      assert_nil result
    end

    it 'loads samples when with_samples option provided' do
      assert_empty repo.find(section.id, repo.with_samples).samples

      Paleolog::Repo.save(Paleolog::Sample.new(name: 'Sample1', section: section))
      Paleolog::Repo.save(Paleolog::Sample.new(name: 'Sample2', section: section))

      result = repo.find(section.id, repo.with_samples)

      assert_equal 2, result.samples.size
      assert_equal %w[Sample1 Sample2], result.samples.map(&:name)
    end
  end

  describe '#similar_name_exists?' do
    it 'checks name uniqueness within project scope' do
      common_name = 'Some name'
      Paleolog::Repo.save(Paleolog::Section.new(name: common_name, project_id: project_id))

      assert(repo.similar_name_exists?(common_name, project_id: project_id))
      refute(repo.similar_name_exists?("#{common_name}123", project_id: project_id))
    end

    it 'does not check name uniqueness accross different projects' do
      common_name = 'Some name'
      other_project_id = Paleolog::Repo.save(Paleolog::Project.new(name: 'Other project'))
      Paleolog::Repo.save(Paleolog::Section.new(name: common_name, project_id: project_id))

      refute(repo.similar_name_exists?(common_name, project_id: other_project_id))
    end

    it 'is case insensitive' do
      Paleolog::Repo.save(Paleolog::Section.new(name: 'Some name', project_id: project_id))

      assert(repo.similar_name_exists?('soMe nAmE', project_id: project_id))
    end
  end
end
