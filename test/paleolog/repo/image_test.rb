# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Image do
  let(:repo) { Paleolog::Repo::Image }

  after do
    repo.delete_all
  end

  describe '#all_for_species' do
    let(:group_id) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Group')) }
    let(:species_id) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Species', group_id: group_id)) }
    let(:other_species_id) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Other Species', group_id: group_id)) }

    it 'returns all features defined for a species' do
      image1_id = Paleolog::Repo.save(Paleolog::Image.new(image_file_name: 'img1.png', species_id: species_id))
      image2_id = Paleolog::Repo.save(Paleolog::Image.new(image_file_name: 'img2.png', species_id: species_id))
      Paleolog::Repo.save(Paleolog::Image.new(image_file_name: 'img3.png', species_id: other_species_id))

      result = repo.all_for_species(species_id)

      assert_equal([image1_id, image2_id], result.map(&:id))
    end
  end
end
