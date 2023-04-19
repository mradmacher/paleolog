# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Sample do
  let(:repo) { Paleolog::Repo::Sample }

  after do
    repo.delete_all
  end

  describe '#find_for_section' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Some Project')) }
    let(:section) { Paleolog::Repo.save(Paleolog::Section.new(name: 'Some Section', project: project)) }
    let(:other_section) { Paleolog::Repo.save(Paleolog::Section.new(name: 'Other Section', project: project)) }

    it 'returns sample by id for given section' do
      sample = Paleolog::Repo.save(Paleolog::Sample.new(name: 'S1', section: section))
      Paleolog::Repo.save(Paleolog::Sample.new(name: 'S2', section: other_section))

      result = repo.find_for_section(sample.id, section.id)
      assert_equal(sample, result)

      result = repo.find_for_section(sample.id, other_section.id)
      assert_nil(result)
    end
  end

  describe '#all_for_section' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Some Project')) }
    let(:section) { Paleolog::Repo.save(Paleolog::Section.new(name: 'Some Section', project: project)) }
    let(:other_section) { Paleolog::Repo.save(Paleolog::Section.new(name: 'Other Section', project: project)) }

    it 'returns samples for given section' do
      sample1 = Paleolog::Repo.save(Paleolog::Sample.new(name: 'S1', section: section))
      sample2 = Paleolog::Repo.save(Paleolog::Sample.new(name: 'S2', section: section))
      Paleolog::Repo.save(Paleolog::Sample.new(name: 'S3', section: other_section))

      result = repo.all_for_section(section.id)
      assert_equal([sample1.id, sample2.id].sort, result.map(&:id).sort)
    end
  end

  describe '#similar_name_exists?' do
    let(:section) { Paleolog::Repo::Section.create(name: 'Some section') }

    it 'checks name uniqueness within section scope' do
      repo.create(name: 'Some sample', section_id: section.id)

      assert(repo.similar_name_exists?('Some sample', section_id: section.id))
      refute(repo.similar_name_exists?('Other sample', section_id: section.id))
    end

    it 'is case insensitive' do
      repo.create(name: 'Some sample', section_id: section.id)

      assert(repo.similar_name_exists?('soMe sAmPle', section_id: section.id))
    end
  end

  describe '#rank_exists_within_section?' do
    let(:section) { Paleolog::Repo::Section.create(name: 'Some section') }

    it 'checks rank uniqueness within section scope' do
      repo.create(name: 'Some sample', rank: 1, section_id: section.id)

      assert(repo.rank_exists_within_section?(1, section.id))
      refute(repo.rank_exists_within_section?(2, section.id))
    end
  end
end
