# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Section do
  let(:repo) { Paleolog::Repo::Section }

  after do
    Paleolog::Repo::Project.delete_all
    repo.delete_all
  end

  describe '#find_for_project' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Some Project')) }
    let(:other_project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Other Project')) }

    it 'returns section by id for given project' do
      section = Paleolog::Repo.save(Paleolog::Section.new(name: 'S1', project: project))
      Paleolog::Repo.save(Paleolog::Section.new(name: 'S2', project: other_project))

      result = repo.find_for_project(section.id, project.id)
      assert_equal(section, result)

      result = repo.find_for_project(section.id, other_project.id)
      assert_nil(result)
    end

    it 'loads samples' do
      section = Paleolog::Repo.save(Paleolog::Section.new(name: 'Section', project: project))
      sample1 = Paleolog::Repo.save(Paleolog::Sample.new(name: 'S1', section: section))
      sample2 = Paleolog::Repo.save(Paleolog::Sample.new(name: 'S2', section: section))

      result = repo.find_for_project(section.id, project.id)
      assert_equal([sample1.id, sample2.id].sort, result.samples.map(&:id).sort)
    end
  end

  describe '#all_for_project' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Some Project')) }
    let(:other_project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Other Project')) }

    it 'returns sections for given project' do
      section1 = Paleolog::Repo.save(Paleolog::Section.new(name: 'S1', project: project))
      section2 = Paleolog::Repo.save(Paleolog::Section.new(name: 'S2', project: project))
      Paleolog::Repo.save(Paleolog::Section.new(name: 'S3', section: other_project))

      result = repo.all_for_project(project.id)
      assert_equal([section1.id, section2.id].sort, result.map(&:id).sort)
    end
  end

  describe '#find' do
    before do
      @project = Paleolog::Repo.save(Paleolog::Project.new(name: 'Some project'))
      @section = Paleolog::Repo.save(Paleolog::Section.new(name: 'Some section', project: @project))
    end

    it 'returns section with given id' do
      result = repo.find(@section.id)
      assert_equal(@section, result)
    end

    it 'returns nil when section with given id does not exist' do
      result = repo.find(@section.id + 1)
      assert_nil result
    end

    it 'loads samples when with_samples option provided' do
      assert_empty repo.find(@section.id, repo.with_samples).samples

      Paleolog::Repo.save(Paleolog::Sample.new(name: 'Sample1', section: @section))
      Paleolog::Repo.save(Paleolog::Sample.new(name: 'Sample2', section: @section))

      result = repo.find(@section.id, repo.with_samples)
      assert_equal 2, result.samples.size
      assert_equal %w[Sample1 Sample2], result.samples.map(&:name)
    end
  end

  describe '#similar_name_exists?' do
    before do
      @project = Paleolog::Repo.save(Paleolog::Project.new(name: 'Some project'))
    end

    it 'checks name uniqueness within project scope' do
      common_name = 'Some name'
      @section = Paleolog::Repo.save(Paleolog::Section.new(name: common_name, project: @project))

      assert(repo.similar_name_exists?(common_name, project_id: @project.id))
      refute(repo.similar_name_exists?("#{common_name}123", project_id: @project.id))
    end

    it 'does not check name uniqueness accross different projects' do
      common_name = 'Some name'
      other_project = Paleolog::Repo.save(Paleolog::Project.new(name: 'Other project'))
      @section = Paleolog::Repo.save(Paleolog::Section.new(name: common_name, project: @project))

      refute(repo.similar_name_exists?(common_name, project_id: other_project.id))
    end

    it 'is case insensitive' do
      @section = Paleolog::Repo.save(Paleolog::Section.new(name: 'Some name', project: @project))

      assert(repo.similar_name_exists?('soMe nAmE', project_id: @project.id))
    end
  end
end
