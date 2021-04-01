# frozen_string_literal: true

require 'features_helper'

describe 'Catalog' do
  let(:group_repository) { Paleolog::Repository::Group.new(Paleolog::Repository::Config.db) }
  let(:species_repository) { Paleolog::Repository::Species.new(Paleolog::Repository::Config.db) }

  before do
    species_repository.clear
    group_repository.clear

    group1 = group_repository.create(name: 'Dinoflagellate')
    group2 = group_repository.create(name: 'Other')
    group_repository.add_species(group1, name: 'Odontochitina costata', verified: true)
    group_repository.add_species(group1, name: 'Cerodinium costata', verified: false)
    group_repository.add_species(group2, name: 'Cerodinium diabelli', verified: true)
  end

  it 'displays species' do
    visit '/catalog'

    page.must_have_content('Species list (2)')
    within('#species-list') do
      page.must_have_css('.species', count: 2)
    end
  end

  it 'displays all when searching with empty criteria' do
    visit '/catalog'

    within('#species-search') do
      click_on('Search')
    end
    page.must_have_content('Species list (2)')
    page.must_have_content('Odontochitina costata')
    page.must_have_content('Cerodinium diabelli')
  end

  it 'allows searching species' do
    visit '/catalog'

    within('#species-search') do
      fill_in('Name', with: 'costa')
      select('Dinoflagellate', from: 'Group')
      click_on('Search')
    end
    page.must_have_content('Species list (1)')
    within('#species-list') do
      page.must_have_css('.species', count: 1)
    end
    page.must_have_content('Odontochitina costata')
  end
end
