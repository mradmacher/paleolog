# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Project do
  let(:repo) { Paleolog::Repo::Project }

  after do
    repo.delete_all
  end

  describe '#find' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Test Project')) }

    it 'loads users' do
      user = Paleolog::Repo.save(
        Paleolog::User.new(login: 'Test User', password: 'Test123'),
      )
      Paleolog::Repo.save(
        Paleolog::Researcher.new(
          user: user,
          project: project,
          created_at: Time.now,
          updated_at: Time.now,
        ),
      )

      result = repo.find(project.id, repo.with_researchers)
      refute_empty(result.researchers, 'researchers are empty')
      assert_equal(1, result.researchers.size)
      result.researchers
      assert_equal('Test User', result.researchers.first.user.login)
    end

    it 'loads countings' do
      Paleolog::Repo.save(
        Paleolog::Counting.new(name: 'Test Counting', project: project),
      )
      result = repo.find(project.id, repo.with_countings)
      refute_empty(result.countings, 'countings are empty')
      assert_equal(1, result.countings.size)
      assert_equal('Test Counting', result.countings.first.name)
    end

    it 'loads sections' do
      Paleolog::Repo.save(
        Paleolog::Section.new(name: 'Test Section', project: project),
      )
      result = repo.find(project.id, repo.with_sections)
      refute_empty(result.sections, 'sections are empty')
      assert_equal(1, result.sections.size)
      assert_equal('Test Section', result.sections.first.name)
    end
  end

  describe '#similar_name_exists?' do
    it 'checks name uniqueness' do
      repo.create(name: 'Some name')

      assert(repo.similar_name_exists?('Some name'))
      refute(repo.similar_name_exists?('Other name'))
    end

    it 'is case insensitive' do
      repo.create(name: 'Some name')

      assert(repo.similar_name_exists?('sOme NamE'))
    end
  end
end
