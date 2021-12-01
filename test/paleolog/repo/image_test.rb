# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Image do
  let(:repo) { Paleolog::Repo::Image.new }

  after do
    repo.delete_all
  end

  describe '#all_for_species' do
    let(:group) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Group')) }
    let(:species) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Species', group: group)) }
    let(:other_species) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Other Species', group: group)) }

    it 'returns all features defined for a species' do
      image1 = Paleolog::Repo.save(Paleolog::Image.new(image_file_name: 'img1.png', species: species))
      image2 = Paleolog::Repo.save(Paleolog::Image.new(image_file_name: 'img2.png', species: species))
      Paleolog::Repo.save(Paleolog::Image.new(image_file_name: 'img3.png', species: other_species))

      result = repo.all_for_species(species.id)
      assert_equal([image1.id, image2.id], result.map(&:id))
    end
  end
end
