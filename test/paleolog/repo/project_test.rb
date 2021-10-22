# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Project do
  before do
    @repo = Paleolog::Repo::Project.new
  end

  after do
    @repo.delete_all
  end

  describe '#find' do
    before do
      @project = Paleolog::Repo.save(Paleolog::Project.new(name: 'Test Project'))
    end

    it 'loads users' do
      user = Paleolog::Repo.save(
        Paleolog::User.new(login: 'Test User', password: 'Test123')
      )
      Paleolog::Repo.save(
        Paleolog::ResearchParticipation.new(
          user: user,
          project: @project,
          created_at: Time.now,
          updated_at: Time.now
        )
      )

      result = @repo.find(@project.id)
      refute result.research_participations.empty?, 'research participations are empty'
      assert 1, result.research_participations.size
      assert 'Test User', result.research_participations.first.user.name
    end

    it 'loads countings' do
      Paleolog::Repo.save(
        Paleolog::Counting.new(name: 'Test Counting', project: @project)
      )
      result = @repo.find(@project.id)
      refute result.countings.empty?, 'countings are empty'
      assert 1, result.countings.size
      assert 'Test Counting', result.countings.first.name
    end

    it 'loads sections' do
      Paleolog::Repo.save(
        Paleolog::Section.new(name: 'Test Section', project: @project)
      )
      result = @repo.find(@project.id)
      refute result.sections.empty?, 'sections are empty'
      assert 1, result.sections.size
      assert 'Test Section', result.sections.first.name
    end
  end

  describe '#name_exists?' do
    it 'checks name uniqueness' do
      @repo.create(name: 'Some name')

      assert(@repo.name_exists?('Some name'))
      refute(@repo.name_exists?('Other name'))
    end

    it 'is case insensitive' do
      @repo.create(name: 'Some name')

      assert(@repo.name_exists?('sOme NamE'))
    end
  end
end
