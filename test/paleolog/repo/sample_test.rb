# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Sample do
  let(:repo) { Paleolog::Repo::Sample }
  let(:project_id) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Some Project')) }
  let(:section_id) { Paleolog::Repo.save(Paleolog::Section.new(name: 'Some Section', project_id: project_id)) }

  after do
    repo.delete_all
    Paleolog::Repo.delete_all(Paleolog::Section)
    Paleolog::Repo.delete_all(Paleolog::Project)
  end

  describe '#find_for_section' do
    let(:other_section_id) { Paleolog::Repo.save(Paleolog::Section.new(name: 'Other Section', project_id: project_id)) }

    it 'returns sample by id for given section' do
      sample_id = Paleolog::Repo.save(Paleolog::Sample.new(name: 'S1', section_id: section_id))
      Paleolog::Repo.save(Paleolog::Sample.new(name: 'S2', section_id: other_section_id))

      result = repo.find_for_section(sample_id, section_id)
      assert_equal(sample_id, result.id)

      result = repo.find_for_section(sample_id, other_section_id)
      assert_nil(result)
    end
  end

  describe '#all_for_section' do
    let(:other_section_id) { Paleolog::Repo.save(Paleolog::Section.new(name: 'Other Section', project_id: project_id)) }

    it 'returns samples for given section' do
      sample1_id = Paleolog::Repo.save(Paleolog::Sample.new(name: 'S1', section_id: section_id))
      sample2_id = Paleolog::Repo.save(Paleolog::Sample.new(name: 'S2', section_id: section_id))
      Paleolog::Repo.save(Paleolog::Sample.new(name: 'S3', section_id: other_section_id))

      result = repo.all_for_section(section_id)
      assert_equal([sample1_id, sample2_id].sort, result.map(&:id).sort)
    end
  end

  describe '#similar_name_exists?' do
    it 'checks name uniqueness within section scope' do
      repo.create(name: 'Some sample', section_id: section_id)

      assert(repo.similar_name_exists?('Some sample', section_id: section_id))
      refute(repo.similar_name_exists?('Other sample', section_id: section_id))
    end

    it 'is case insensitive' do
      repo.create(name: 'Some sample', section_id: section_id)

      assert(repo.similar_name_exists?('soMe sAmPle', section_id: section_id))
    end
  end

  describe '#rank_exists_within_section?' do
    it 'checks rank uniqueness within section scope' do
      repo.create(name: 'Some sample', rank: 1, section_id: section_id)

      assert(repo.rank_exists_within_section?(1, section_id))
      refute(repo.rank_exists_within_section?(2, section_id))
    end
  end
end
